# Web Deploy

Production web hosting is the image built from the repo-root [`Dockerfile.web`](../../../Dockerfile.web) and published by [`.github/workflows/deploy-web.yml`](../../../.github/workflows/deploy-web.yml). The image is the IAClé brand (`BRAND=iacle` from `brand/iacle`) on the PistisAI base. Dokploy pulls that image. Traefik routes to it only after the container healthcheck passes. Public ingress stays the Cloudflare Tunnel already running in front of Dokploy.

A second Dockerfile, [`config/docker/Dockerfile.web`](../../../config/docker/Dockerfile.web), is the compose path. It does not compile Flutter. It serves an already-built `build/web/` tree on port `8080` as a non-root user. Do not use it to reproduce the Dokploy image.

## What the production image does

The builder is `gmeligio/flutter-android:3.47.7` (match `environment.flutter` in `pubspec.yaml`). That image does not enable Flutter web on its own, so the Dockerfile runs `flutter config --enable-web` before `flutter build web`.

The release build passes `--no-web-resources-cdn` and `--dart-define=BRAND=iacle`. The site content policy blocks the Google-hosted CanvasKit script. With the CDN build, the Flutter view never paints and the splash clears to a white page. CanvasKit must be served from this origin. The same build also requires `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `PISTISAI_ADMIN_EMAIL`. The Dockerfile refuses to compile when any of those three is empty.

After the Flutter build, the Dockerfile reads `assets/version.json` and replaces the literal `$FLUTTER_BUILD_NUMBER` in `build/web/index.html` with `{version}.{build_number}`. The source file [`web/index.html`](../../../web/index.html) keeps the placeholder. A local `flutter build web` does not perform that replacement.

The runtime stage is `nginx:alpine`. It copies `build/web` and the repo-root [`nginx.conf`](../../../nginx.conf), listens on port 80, and healthchecks with:

```dockerfile
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=5 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1/ || exit 1
```

Use `127.0.0.1`, not `localhost`. In this image `localhost` can resolve to IPv6 while nginx is listening on IPv4, so the check fails and Traefik keeps the container out of rotation.

`.dockerignore` drops `android/`, `docs/`, `*.md`, and `pubspec.lock` from the build context. `flutter pub get` inside the image resolves from `pubspec.yaml` constraints, not from the lockfile on the developer machine.

## Cache rules

`nginx.conf` is a single server. It is not the domain-split proxy sketched in [Unified Flutter Web](../../architecture/UNIFIED_FLUTTER_WEB.md).

| Request | Policy |
| --- | --- |
| `/` and other paths that miss the rules below, including `index.html` and `*.wasm` | `Cache-Control: no-cache` |
| Exact path `/flutter_bootstrap.js` (query string ignored) | `Cache-Control: no-cache` |
| Other `.js`, `.css`, images, and fonts | 1 year, `public, immutable` |

The exact `flutter_bootstrap.js` location exists because the long-cache regex would otherwise match it. Browsers that kept an immutable copy of the old bootstrap kept loading the blocked CanvasKit URL after the image changed. The version query string on the script tag changes only when the image build substitutes `$FLUTTER_BUILD_NUMBER`.

## Pipeline

`deploy-web.yml` runs when [Auto Version Bump](../../../.github/workflows/auto-version-bump.yml) completes on `main`, or on `workflow_dispatch`.

1. **analyze** — Flutter pin from `pubspec.yaml` on `ubuntu-24.04`, `flutter pub get`, `flutter analyze lib/`. Skipped when the triggering bump workflow failed.
2. **build_and_push** — Build `Dockerfile.web` with `BRAND=iacle` and push `ghcr.io/<repository owner>/iacle-app-web:{version}` and `:latest`. For this repository that image is `ghcr.io/iacle-solutions/iacle-app-web`. `{version}` is the `version` field in `assets/version.json`. The job fails if the build action returns no digest. It then tries to mark the GHCR package public.
3. **deploy_dokploy** — POST `DOKPLOY_WEBHOOK_URL`, then purge the Cloudflare cache. The Cloudflare Tunnel is not redeployed by this job.

Desktop, mobile, and backend workflows start from a completed Web Deploy run. They do not start from the version bump directly. See [CI/CD Quick Reference](CI_CD_QUICK_REFERENCE.md).

### Dokploy trigger

The Dokploy application should use the Docker image `ghcr.io/<repository owner>/iacle-app-web:latest` (here, `ghcr.io/iacle-solutions/iacle-app-web:latest`). Copy that application's deploy webhook into the Actions secret `DOKPLOY_WEBHOOK_URL`.

`scripts/ci/trigger_dokploy_deploy.sh` POSTs a push-shaped JSON body (`ref` and `head_commit.id`) with `X-GitHub-Event: push`. HTTP `200`, `201`, or `202` counts as triggered. Any other status fails the deploy step. The script does not print the webhook URL.

When `DOKPLOY_WEBHOOK_URL` is unset, the step prints `DOKPLOY_WEBHOOK_URL is not set — skipping Dokploy deploy` and exits 0. The image is still published. The rest of the workflow does not fail.

`DOKPLOY_API_KEY` is optional. When it is set, the same request sends it as the `x-api-key` header. Use that when the URL is a Dokploy API deploy endpoint that requires a token. The webhook URL from the application page does not need the key. The key alone cannot target an application, so a missing webhook still skips the deploy.

### GHCR pull

After the push, the workflow calls the GitHub packages API and sets the container package visibility to `public`. A public package is what lets Dokploy pull `:latest` without a registry login.

If that API call fails, the step still succeeds and prints that Dokploy needs a registry credential. In Dokploy, add a registry for `ghcr.io` whose username is a GitHub account and whose password is a token with `read:packages`. Point the application at `ghcr.io/iacle-solutions/iacle-app-web:latest`.

### Tunnel and cache purge

The Cloudflare Tunnel stays the public ingress. `docker-compose.yml` runs `cloudflared` with `CLOUDFLARE_TUNNEL_TOKEN`. This workflow does not SSH to the host and does not rewrite tunnel ingress. Dokploy and Traefik sit behind that tunnel. Traefik only attaches the new container after the image healthcheck passes.

Cloudflare purge runs with `if: always()`, including when the webhook was skipped or failed. It no-ops when `CLOUDFLARE_CACHE_PURGE_TOKEN` or `CF_ZONE_ID` is unset, and a failed purge does not fail the job. The nginx `no-cache` rules above are what stop browsers from pinning `flutter_bootstrap.js`. The purge is an extra flush, not the cache fix.

## Local checks

```bash
# Production image (compiles Flutter web). The three auth args are required.
docker build -f Dockerfile.web -t IAClé-web \
  --build-arg BRAND=iacle \
  --build-arg SUPABASE_URL="$SUPABASE_URL" \
  --build-arg SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --build-arg PISTISAI_ADMIN_EMAIL="$PISTISAI_ADMIN_EMAIL" \
  .

# Compose image (requires build/web first)
flutter build web --release --no-web-resources-cdn --dart-define=BRAND=iacle
docker build -f config/docker/Dockerfile.web -t IAClé-web-prebuilt .
```

Confirm the production image substituted the bootstrap version and answers on IPv4:

```bash
docker run --rm IAClé-web \
  grep -o 'flutter_bootstrap.js?v=[^"]*' /usr/share/nginx/html/index.html
```

The printed query value should be `{version}.{build_number}` from `assets/version.json`, not the literal `$FLUTTER_BUILD_NUMBER`.

## Troubleshooting

### Site stays on the Traefik 404

The container is not healthy, or Dokploy has not attached it to the route. Check the image healthcheck uses `http://127.0.0.1/` and that the webhook step printed `Dokploy deploy triggered`. The Cloudflare Tunnel must already point at Traefik. This workflow does not recreate the tunnel.

### Blank page after the splash

The browser loaded a CanvasKit URL on `gstatic.com`, or it is still executing an old `flutter_bootstrap.js`. Rebuild with `--no-web-resources-cdn`. Confirm `index.html` references `flutter_bootstrap.js?v=` plus the current version, and that a direct request for `/flutter_bootstrap.js` returns `Cache-Control: no-cache`.

### GHCR pull fails on the Dokploy host

The package is still private and Dokploy has no registry credential. Confirm the workflow log says `GHCR package is public`, or add a `ghcr.io` registry in Dokploy with `read:packages`. The image name must be `ghcr.io/<repository owner>/iacle-app-web:latest`, not a package owned by another account.

### Web image build cannot see the lockfile or Android project

That is `.dockerignore`. Android sources are not part of the web image. Dependency resolution uses `pubspec.yaml` only.

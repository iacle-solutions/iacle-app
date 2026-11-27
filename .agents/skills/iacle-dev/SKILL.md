---
name: iacle-dev
description: Developer workflow for this repository. IAClé is PistisAI renamed for the Québec market (same codebase and product; IAClé brand, assets, and deploy targets).
---

# IAClé development

IAClé is PistisAI renamed for the Québec market. Same codebase, same product. The brand, assets, READMEs, and deploy targets are IAClé's. User-facing copy and hosts come from `brand/iacle/brand.yaml`.

## Layout

- `lib/main.dart`, `lib/di/locator.dart` — app entry. `setupCoreServices()` then `setupAuthenticatedServices()`.
- `lib/services/router_server.dart` — embedded router, port `1337`, loopback unless `authSecret` is set.
- `lib/database/` — Drift/SQLite. Do not edit `*.g.dart`. Regenerate with `dart run build_runner build --delete-conflicting-outputs`.
- `services/api-backend/` — Express 5 ESM, `PORT || 8080`. Tests live at `test/api-backend/`.
- `services/streaming-proxy/` — Express 5 ESM, `PORT || 3001`.
- `services/tailscale-relay/` — Express 4 ESM, `PORT || 3002`.
- `backend/auth/` — Express 5 CommonJS, `PORT || 3000`, entry `handlers.js`. No `npm run dev`.
- `services/sdk/` — TypeScript ESM, Node `>=18`. Run `npm run build` before use.
- `lib/shared/` — separate Dart package. Its own `flutter pub get`.

Node is pinned by `.nvmrc` (26). Service engines require Node `>=26 <28`. Flutter is pinned by `environment.flutter` in `pubspec.yaml` (3.47.9).

Do not import `dart:io` in shared code. Use conditional imports (`dart.library.io` / `dart.library.html`).

## Brand

```bash
# IACLE_BRAND_LICENCE is the licence JSON. The script does not print it.
bash scripts/ci/bake_iacle_brand.sh
flutter build web --release --no-web-resources-cdn --dart-define=BRAND=iacle
bash tool/brand_leak_check.sh build/web
```

`tool/brand.sh iacle` refuses to run without a licence. `pistisai` and `example` bake without one. Release jobs bake IAClé before they build. The licence is `IACLE_BRAND_LICENCE` and is never printed.

Preserved IAClé endpoints in `brand/iacle/brand.yaml`: `api_base_url` `https://api.iacle.app`, `ws_endpoint`, `tunnel_ssh_url`, `streaming_base_url`, `admin_center_url`, `url_scheme: iacle`, and the Cloudflare Access team domain and audience.

## Checks

```bash
flutter pub get
cd lib/shared && flutter pub get && cd ../..
flutter analyze lib/
bash scripts/ci/flutter_security_basic_tests.sh
```

Backend, from the repo root: `npm test` runs the api-backend security suite. There is no `npm run db:migrate`. Auth starts with `node handlers.js`.

## Git

Every change goes through a pull request. Commit subjects use `feat:`, `fix:`, `docs:`, `chore:`, `test:`, or `refactor:` with an agent prefix when an agent writes the commit. Do not force-push `main`. Deploys run only through GitHub Actions. Each deploy triggers Dokploy and purges the whole Cloudflare zone, and the deploy fails if the purge fails.

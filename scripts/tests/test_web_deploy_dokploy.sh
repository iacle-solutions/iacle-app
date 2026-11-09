#!/usr/bin/env bash
# The web workflow deploys through Dokploy and skips cleanly when the webhook
# secret is absent. It must not print the webhook URL.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/deploy-web.yml"
TRIGGER="$ROOT/scripts/ci/trigger_dokploy_deploy.sh"

fail() {
  echo "test_web_deploy_dokploy: $*" >&2
  exit 1
}

[ -f "$WORKFLOW" ] || fail "missing $WORKFLOW"
[ -f "$TRIGGER" ] || fail "missing $TRIGGER"
bash -n "$TRIGGER"

previous_host="$(printf '%s%s' 'cool' 'ify')"
if grep -Ei "${previous_host}|${previous_host^^}_" "$WORKFLOW" >/dev/null; then
  fail "workflow still names the previous host panel"
fi
grep -Fq 'DOKPLOY_WEBHOOK_URL: ${{ secrets.DOKPLOY_WEBHOOK_URL }}' "$WORKFLOW" \
  || fail "workflow does not read DOKPLOY_WEBHOOK_URL"
grep -Fq 'DOKPLOY_API_KEY: ${{ secrets.DOKPLOY_API_KEY }}' "$WORKFLOW" \
  || fail "workflow does not read DOKPLOY_API_KEY"
grep -Fq 'BRAND=iacle' "$WORKFLOW" || fail "brand build arg missing"
grep -Fq 'CLOUDFLARE_CACHE_PURGE_TOKEN' "$WORKFLOW" || fail "cache purge missing"
grep -Fq 'bash scripts/ci/trigger_dokploy_deploy.sh' "$WORKFLOW" \
  || fail "workflow does not call the Dokploy trigger"
grep -Fq "if: steps.dokploy.outputs.skipped != 'true' && success()" "$WORKFLOW" \
  || fail "site check is not limited to a successful Dokploy trigger"
if grep -Fq '/visibility' "$WORKFLOW"; then
  fail "workflow still calls the unsupported package visibility API"
fi
grep -Fq 'cannot change package visibility' "$WORKFLOW" \
  || fail "workflow does not say the package stays private"
grep -Fq 'read:packages' "$ROOT/docs/operations/cicd/WEB_DEPLOY.md" \
  || fail "deploy doc does not tell Dokploy how to pull a private image"
grep -Fq 'does not try' "$ROOT/docs/operations/cicd/WEB_DEPLOY.md" \
  || fail "deploy doc still claims the workflow changes package visibility"
if grep -E '[0-9]{1,3}(\.[0-9]{1,3}){3}' "$WORKFLOW" >/dev/null; then
  fail "workflow contains an IP address"
fi

if git -C "$ROOT" grep -I -i -n -e "$previous_host" -- ':!CHANGELOG.md' ':!**/CHANGELOG.md' >/tmp/previous-host-hits.txt; then
  cat /tmp/previous-host-hits.txt >&2
  fail "previous host-panel reference remains outside a changelog"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cat >"$tmpdir/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${CURL_ARGS_FILE:?}"
if [ "${CURL_EXIT:-0}" -ne 0 ]; then
  echo "curl failed" >&2
  exit "$CURL_EXIT"
fi
printf '%s' "${CURL_HTTP_CODE:?}"
EOF
chmod 755 "$tmpdir/curl"

run_trigger() {
  PATH="$tmpdir:$PATH" \
    CURL_ARGS_FILE="$tmpdir/args" \
    bash "$TRIGGER"
}

skip_out="$(env -u DOKPLOY_WEBHOOK_URL -u DOKPLOY_API_KEY bash "$TRIGGER")"
printf '%s' "$skip_out" | grep -Fq 'DOKPLOY_WEBHOOK_URL is not set — skipping Dokploy deploy' \
  || fail "missing webhook did not skip: $skip_out"

secret_url='https://example.invalid/api/deploy/secret-token'
ok_out="$(
  CURL_HTTP_CODE=200 \
    DOKPLOY_WEBHOOK_URL="$secret_url" \
    DOKPLOY_API_KEY='test-key' \
    GITHUB_SHA='abc123' \
    GITHUB_REF='refs/heads/main' \
    run_trigger
)"
printf '%s' "$ok_out" | grep -Fq 'Dokploy deploy triggered' || fail "200 did not trigger: $ok_out"
printf '%s' "$ok_out" | grep -Fq 'secret-token' && fail "trigger printed the webhook URL"
grep -Fq 'x-api-key: test-key' "$tmpdir/args" || fail "API key header was not sent"
grep -Fq 'X-GitHub-Event: push' "$tmpdir/args" || fail "push event header missing"

set +e
bad_out="$(
  CURL_HTTP_CODE=500 \
    DOKPLOY_WEBHOOK_URL="$secret_url" \
    run_trigger 2>&1
)"
bad_status=$?
set -e
[ "$bad_status" -ne 0 ] || fail "HTTP 500 should fail the deploy"
printf '%s' "$bad_out" | grep -Fq 'HTTP 500' || fail "HTTP 500 message missing: $bad_out"
printf '%s' "$bad_out" | grep -Fq 'secret-token' && fail "failure output printed the webhook URL"

set +e
curl_fail_out="$(
  CURL_HTTP_CODE=200 \
    CURL_EXIT=7 \
    DOKPLOY_WEBHOOK_URL="$secret_url" \
    run_trigger 2>&1
)"
curl_fail_status=$?
set -e
[ "$curl_fail_status" -ne 0 ] || fail "curl failure should fail the deploy"
printf '%s' "$curl_fail_out" | grep -Fq 'The URL is not printed.' \
  || fail "curl failure message missing: $curl_fail_out"
printf '%s' "$curl_fail_out" | grep -Fq 'secret-token' && fail "curl error printed the webhook URL"

echo "[test_web_deploy_dokploy] Passed"

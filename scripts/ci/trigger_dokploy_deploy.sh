#!/usr/bin/env bash
# Ask Dokploy to pull the image this workflow just published.
# DOKPLOY_WEBHOOK_URL is the application webhook. DOKPLOY_API_KEY is optional
# and is sent as x-api-key when set. The URL and the key are never printed.
# A missing webhook fails the deploy. Deploys run only from GitHub Actions.
set -euo pipefail

if [ -z "${DOKPLOY_WEBHOOK_URL:-}" ]; then
  echo "❌ DOKPLOY_WEBHOOK_URL is not set. Refusing to skip the deploy."
  exit 1
fi

ref="${GITHUB_REF:-refs/heads/main}"
sha="${GITHUB_SHA:-}"
payload="$(jq -n --arg ref "$ref" --arg sha "$sha" \
  '{ref: $ref, head_commit: {id: $sha, message: "Image published"}}')"

echo "Triggering Dokploy deploy..."
args=(
  -sS
  --max-time 60
  -o /tmp/dokploy-deploy.json
  -w "%{http_code}"
  -X POST
  "$DOKPLOY_WEBHOOK_URL"
  -H "Content-Type: application/json"
  -H "Accept: application/json"
  -H "X-GitHub-Event: push"
  --data "$payload"
)
if [ -n "${DOKPLOY_API_KEY:-}" ]; then
  args+=(-H "x-api-key: ${DOKPLOY_API_KEY}")
fi

set +e
http_code="$(curl "${args[@]}" 2>/tmp/dokploy-curl.err)"
status=$?
set -e
if [ "$status" -ne 0 ]; then
  echo "❌ Dokploy webhook request failed. The URL is not printed."
  exit 1
fi

echo "Dokploy webhook HTTP ${http_code}"
case "$http_code" in
  200|201|202)
    echo "✅ Dokploy deploy triggered"
    ;;
  *)
    echo "❌ Dokploy webhook returned HTTP ${http_code}"
    exit 1
    ;;
esac

#!/usr/bin/env bash
# Ask Dokploy to pull the image that this workflow just published.
# DOKPLOY_WEBHOOK_URL is the application webhook (or an API deploy URL).
# DOKPLOY_API_KEY is optional. When set, it is sent as x-api-key.
# A missing webhook skips the deploy. The URL and key are never printed.
set -euo pipefail

if [ -z "${DOKPLOY_WEBHOOK_URL:-}" ]; then
  echo "DOKPLOY_WEBHOOK_URL is not set — skipping Dokploy deploy"
  exit 0
fi

ref="${GITHUB_REF:-refs/heads/main}"
sha="${GITHUB_SHA:-}"
payload="$(jq -n --arg ref "$ref" --arg sha "$sha" \
  '{ref: $ref, head_commit: {id: $sha, message: "Web image published"}}')"

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
  echo "Dokploy webhook request failed. The URL is not printed."
  exit 1
fi

echo "Dokploy webhook HTTP ${http_code}"
case "$http_code" in
  200|201|202)
    echo "Dokploy deploy triggered"
    ;;
  *)
    echo "Dokploy webhook returned HTTP ${http_code}"
    exit 1
    ;;
esac

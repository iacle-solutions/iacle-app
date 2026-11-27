#!/usr/bin/env bash
# Bake brand/iacle into the tree. IAClé is this repository's product name.
# The licence stays in IACLE_BRAND_LICENCE and is never printed.
set -euo pipefail

if [ -z "${IACLE_BRAND_LICENCE:-}" ]; then
  echo "::error::IACLE_BRAND_LICENCE is not set. Refusing to bake."
  exit 66
fi

root="$(cd "$(dirname "$0")/../.." && pwd)"
umask 077
licence="$(mktemp)"
cleanup() {
  rm -f "$licence"
}
trap cleanup EXIT
printf '%s' "$IACLE_BRAND_LICENCE" > "$licence"
bash "$root/tool/brand.sh" iacle --license "$licence"

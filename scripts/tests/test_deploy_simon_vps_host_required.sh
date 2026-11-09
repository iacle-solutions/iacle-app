#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEPLOY_SCRIPT="$PROJECT_ROOT/scripts/deploy-simon-vps.sh"

if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
  echo "Missing deploy script: $DEPLOY_SCRIPT" >&2
  exit 1
fi

python3 - <<'PY' "$DEPLOY_SCRIPT"
from pathlib import Path
import sys

deploy_script = Path(sys.argv[1]).read_text()

required_strings = [
    'SIMON_HOST="${SIMON_HOST:-}"',
    'if [[ -z "$SIMON_HOST" ]]; then',
    'fail "SIMON_HOST is required"',
]
for needle in required_strings:
    if needle not in deploy_script:
        raise SystemExit(f'missing Simon host guard string: {needle}')

import re
if re.search(r'SIMON_HOST="\$\{SIMON_HOST:-[0-9.]+\}"', deploy_script):
    raise SystemExit('Simon deploy script must not default SIMON_HOST to an address')

for forbidden in [
    'SWARM_HOST',
    'K8S_HOST',
    'KUBECONFIG_BASE64',
]:
    if forbidden in deploy_script:
        raise SystemExit(f'Simon deploy script still contains legacy host path: {forbidden}')

print('[test_deploy_simon_vps_host_required] Passed')
PY

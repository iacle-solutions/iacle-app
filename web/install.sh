#!/bin/bash
# IAClé web bootstrap installer — served from iacle.app/install.sh
# Fetches the full release installer (AppImage + desktop entry + update daemon).
set -euo pipefail
exec bash <(curl -fsSL "https://github.com/iacle-solutions/iacle-app/releases/latest/download/install.sh") "$@"

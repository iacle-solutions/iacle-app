#!/bin/bash
# IAClé web bootstrap installer.
# Fetches the full release installer (AppImage + desktop entry + update daemon).
set -euo pipefail
exec bash <(curl -fsSL "https://github.com/pistisAI/pistisai-app/releases/latest/download/install.sh") "$@"

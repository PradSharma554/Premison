#!/usr/bin/env bash
# analyze.sh — Analyze repository structure using aider + DeepSeek
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

aider \
  --config "$SCRIPT_DIR/config/.aider.conf.yml" \
  --model-settings-file "$SCRIPT_DIR/config/.aider.model.settings.yml" \
  --no-auto-commits \
  --message "Analyze this repository's structure. List all important files and directories, describe the architecture, identify entry points, key modules, and how the code is organized. Provide a concise summary."

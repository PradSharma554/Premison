#!/usr/bin/env bash
# implement.sh — Implement a feature described in natural language using aider
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

DESCRIPTION="$1"

if [[ -z "$DESCRIPTION" ]]; then
  echo "Usage: local-agent implement \"description of the feature\""
  exit 1
fi

aider \
  --config "$SCRIPT_DIR/config/.aider.conf.yml" \
  --model-settings-file "$SCRIPT_DIR/config/.aider.model.settings.yml" \
  --no-auto-commits \
  --message "Implement the following feature: $DESCRIPTION

Follow existing code conventions and patterns. Create new files only if necessary. Write clean, well-structured code."

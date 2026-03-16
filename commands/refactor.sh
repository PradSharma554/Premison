#!/usr/bin/env bash
# refactor.sh — Refactor code for clarity using aider
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

TARGET="${1:-}"

if [[ -n "$TARGET" ]]; then
  MSG="Refactor the file or directory '$TARGET' for improved clarity, readability, and maintainability. Do not change external behavior. Simplify complex logic, improve naming, remove dead code, and follow best practices."
else
  MSG="Review this repository and refactor code for improved clarity, readability, and maintainability. Do not change external behavior. Focus on the most impactful improvements: simplify complex logic, improve naming, remove dead code, and follow best practices."
fi

aider \
  --config "$SCRIPT_DIR/config/.aider.conf.yml" \
  --model-settings-file "$SCRIPT_DIR/config/.aider.model.settings.yml" \
  --no-auto-commits \
  --message "$MSG"

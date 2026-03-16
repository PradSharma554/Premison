#!/usr/bin/env bash
# setup.sh — One-time installer for Premison (local AI agent)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
VENV_DIR="$PROJECT_DIR/.venv"
CODING_MODEL="deepseek-coder:6.7b-instruct"
GENERAL_MODEL="qwen3:8b"
SYMLINK_TARGET="/opt/homebrew/bin/local-agent"

echo "=== Premison Setup ==="
echo ""

# 1. Check Ollama is installed
if ! command -v ollama &>/dev/null; then
  echo "Error: Ollama is not installed."
  echo "Install it from https://ollama.ai or via: brew install ollama"
  exit 1
fi
echo "[OK] Ollama is installed ($(ollama --version))"

# 2. Start Ollama if not running
if ! curl -sf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "Starting Ollama..."
  ollama serve >/dev/null 2>&1 &
  for i in {1..15}; do
    sleep 1
    if curl -sf http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      break
    fi
    if [[ $i -eq 15 ]]; then
      echo "Error: Could not start Ollama after 15 seconds."
      echo "Try starting it manually: ollama serve"
      exit 1
    fi
  done
  echo "[OK] Ollama started"
else
  echo "[OK] Ollama is already running"
fi

# 3. Pull coding model (skip if already present)
if ollama list | grep -q "$CODING_MODEL"; then
  echo "[OK] Model $CODING_MODEL is already pulled"
else
  echo "Pulling model $CODING_MODEL (~4GB download)..."
  ollama pull "$CODING_MODEL"
  echo "[OK] Model pulled"
fi

# 4. Pull general-purpose model for Goose (skip if already present)
if ollama list | grep -q "$GENERAL_MODEL"; then
  echo "[OK] Model $GENERAL_MODEL is already pulled"
else
  echo "Pulling model $GENERAL_MODEL (~5GB download)..."
  ollama pull "$GENERAL_MODEL"
  echo "[OK] Model pulled"
fi

# 5. Create Python venv and install aider
# Use Python 3.12 for compatibility (3.13+ has setuptools issues with aider deps)
PYTHON_BIN=""
for candidate in python3.12 /usr/local/bin/python3.12 /opt/homebrew/bin/python3.12; do
  if command -v "$candidate" &>/dev/null || [[ -x "$candidate" ]]; then
    PYTHON_BIN="$candidate"
    break
  fi
done
if [[ -z "$PYTHON_BIN" ]]; then
  echo "Warning: Python 3.12 not found, falling back to python3"
  PYTHON_BIN="python3"
fi

if [[ -f "$VENV_DIR/bin/activate" ]] && "$VENV_DIR/bin/python3" -c "import aider" 2>/dev/null; then
  echo "[OK] Python venv and aider already installed"
else
  echo "Creating Python venv at $VENV_DIR (using $PYTHON_BIN)..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
  echo "Installing aider-chat (this may take a few minutes)..."
  "$VENV_DIR/bin/pip3" install --upgrade pip setuptools wheel >/dev/null 2>&1
  "$VENV_DIR/bin/pip3" install aider-chat
  echo "[OK] aider-chat installed in venv"
fi

# 6. Install Goose CLI
if command -v goose &>/dev/null; then
  echo "[OK] Goose is already installed"
else
  echo "Installing Goose CLI..."
  brew install block-goose-cli
  echo "[OK] Goose installed"
fi

# 7. Create .env file (idempotent)
ENV_FILE="$PROJECT_DIR/.env"
cat > "$ENV_FILE" <<'EOF'
OLLAMA_API_BASE=http://127.0.0.1:11434
OLLAMA_HOST=127.0.0.1:11434
OLLAMA_CONTEXT_LENGTH=32768
EOF
echo "[OK] .env file created"

# 8. Copy Goose config
GOOSE_CONFIG_DIR="$HOME/.config/goose"
mkdir -p "$GOOSE_CONFIG_DIR"
cp "$PROJECT_DIR/config/goose.yaml" "$GOOSE_CONFIG_DIR/config.yaml"
echo "[OK] Goose configured for Ollama + $GENERAL_MODEL"

# 9. Make scripts executable
chmod +x "$PROJECT_DIR/local-agent"
chmod +x "$PROJECT_DIR/commands/"*.sh
echo "[OK] Scripts are executable"

# 10. Create symlink in /opt/homebrew/bin/
if [[ -L "$SYMLINK_TARGET" ]] || [[ -e "$SYMLINK_TARGET" ]]; then
  rm -f "$SYMLINK_TARGET"
fi
ln -sf "$PROJECT_DIR/local-agent" "$SYMLINK_TARGET"
echo "[OK] Symlink created: $SYMLINK_TARGET -> $PROJECT_DIR/local-agent"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Usage:"
echo "  GENERAL:"
echo "  local-agent session              # Full interactive AI session"
echo "  local-agent chat                 # Chat mode (no actions)"
echo "  local-agent do \"list files\"       # One-off task"
echo "  local-agent browse \"search web\"   # Browser automation"
echo ""
echo "  CODING:"
echo "  local-agent                      # Interactive code editing (Aider)"
echo "  local-agent analyze              # Analyze repo structure"
echo "  local-agent implement \"add login\" # Implement a feature"
echo "  local-agent refactor src/utils.py # Refactor a file"
echo "  local-agent fix-tests            # Auto-fix failing tests"
echo "  local-agent help                 # Show all commands"
echo ""
echo "cd into any directory and run 'local-agent session' or 'local-agent' to start!"

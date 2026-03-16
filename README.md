# Premison — Local AI Agent

A fully local, free AI agent that runs in your terminal. Handles general tasks, browser automation, and code editing — all powered by Ollama.

- **General tasks** (chat, file ops, shell commands, browser): Goose + qwen3:8b
- **Code editing**: Aider + deepseek-coder:6.7b

## Prerequisites

- macOS (Apple Silicon)
- [Ollama](https://ollama.ai) installed
- Python 3.10+
- [Homebrew](https://brew.sh) (for Goose CLI install)
- Node.js (optional — only needed for `browse` command)

## Setup

```bash
cd /Users/zopdev/Desktop/This_PC/Coding/AI/Premison
./setup.sh
```

This will:
1. Verify Ollama is installed and start it if needed
2. Pull `deepseek-coder:6.7b-instruct` (~4GB) for code editing
3. Pull `qwen3:8b` (~5GB) for general tasks
4. Create a Python venv and install `aider-chat`
5. Install Goose CLI via Homebrew
6. Configure Goose for Ollama + qwen3:8b
7. Symlink `local-agent` to `/opt/homebrew/bin/` for system-wide access

## Usage

### General Tasks (Goose)

```bash
# Full interactive AI session (chat + tools + file ops)
local-agent session

# Chat mode — ask questions, get explanations (no actions taken)
local-agent chat

# Run a one-off task
local-agent do "list all .py files in this directory"
local-agent do "create a hello world script in Python"

# Browser automation (requires Node.js for Playwright MCP)
local-agent browse "search github for ollama documentation"
```

### Code Editing (Aider)

Navigate to any git repository and run:

```bash
# Start an interactive AI coding session
local-agent

# Analyze repository structure
local-agent analyze

# Implement a feature from a description
local-agent implement "add user authentication with JWT"

# Refactor a specific file or the whole repo
local-agent refactor src/utils.py
local-agent refactor

# Auto-detect and fix failing tests
local-agent fix-tests

# Show help
local-agent help
```

## Commands

| Command | Backend | Description |
|---------|---------|-------------|
| `local-agent session` | Goose | Full interactive session (chat + tools + files) |
| `local-agent chat` | Goose | Conversational mode (questions, explanations) |
| `local-agent do "task"` | Goose | Run a one-off task (file ops, shell, etc.) |
| `local-agent browse "task"` | Goose | Browser automation via Playwright MCP |
| `local-agent` | Aider | Interactive code editing in current git repo |
| `local-agent analyze` | Aider | Analyze repo structure and architecture |
| `local-agent implement "desc"` | Aider | Implement a feature from description |
| `local-agent refactor [file]` | Aider | Refactor code for clarity |
| `local-agent fix-tests` | Aider | Run tests, detect failures, auto-fix |
| `local-agent help` | — | Print usage information |

## Architecture

Premison uses a dual-backend design — each backend is chosen for what it does best:

```
local-agent (bash dispatcher)
├── Goose (by Block)      → general tasks, chat, browser automation
│   └── qwen3:8b via Ollama (32K context)
└── Aider                 → code editing, analysis, refactoring
    └── deepseek-coder:6.7b via Ollama (8K context)
```

**Goose** handles anything that isn't code editing: interactive sessions, one-off shell tasks, file operations, and browser automation (via Playwright MCP). It uses qwen3:8b, which supports native tool calling.

**Aider** handles all code editing workflows: interactive coding sessions, repo analysis, feature implementation, refactoring, and test fixing. It uses deepseek-coder:6.7b-instruct, optimized for code generation.

The `local-agent` script dispatches to the correct backend based on the sub-command. Goose commands (`session`, `chat`, `do`, `browse`) route to Goose; coding commands (`analyze`, `implement`, `refactor`, `fix-tests`, or no command) route to Aider.

## Goose CLI Notes

**Important quirk:** `goose session` does **not** accept `--provider` or `--model` as CLI flags. You must use environment variables instead:

```bash
# session/chat — uses env vars (the only way)
GOOSE_PROVIDER=ollama GOOSE_MODEL=qwen3:8b goose session

# run — accepts CLI flags
goose run --provider ollama --model qwen3:8b -t "task"
```

This is why `local-agent` sets `GOOSE_PROVIDER` and `GOOSE_MODEL` as inline env vars for `session`/`chat`, but uses `--provider`/`--model` flags for `do`/`browse` (which use `goose run`).

**Config file:** `config/goose.yaml` is copied to `~/.config/goose/config.yaml` during setup. This sets the default provider, model, mode, and extensions.

**Context length:** `OLLAMA_CONTEXT_LENGTH=32768` is set in `.env` and is critical — Ollama defaults to 4096, which is far too small for Goose's tool-calling prompts.

## Aider Command Details

All Aider commands share these flags:
- `--config config/.aider.conf.yml` — CLI behavior settings
- `--model-settings-file config/.aider.model.settings.yml` — model/context config
- `--no-auto-commits` — never auto-commit changes

| Command | Script | What it does |
|---------|--------|-------------|
| `analyze` | `commands/analyze.sh` | Sends a repo analysis prompt — lists files, describes architecture, identifies entry points |
| `fix-tests` | `commands/fix-tests.sh` | Auto-detects test runner (pytest / go test / npm test / make test), runs tests, captures failures, passes output to Aider for fixing |
| `implement` | `commands/implement.sh` | Takes a feature description string, sends an implementation prompt following existing conventions |
| `refactor` | `commands/refactor.sh` | Optional target file/dir argument — sends a refactoring prompt focused on clarity and readability without changing behavior |

`fix-tests` detection order: `pytest.ini`/`setup.py`/`pyproject.toml`/`setup.cfg` → pytest, `go.mod` → go test, `package.json` → npm test, `Makefile` with `test:` target → make test.

## Development Notes

- **Goose config** lives at `~/.config/goose/config.yaml` (copied from `config/goose.yaml` by `setup.sh`)
- **Goose extensions:** `developer` is always enabled in config; `playwright` is added on-demand via `--with-extension "npx -y @playwright/mcp@latest"` in the `browse` command
- **Aider requires Python 3.12** specifically — 3.13+ has setuptools compatibility issues with aider dependencies. The setup script searches for `python3.12` first and falls back to `python3`
- **System-wide access:** the symlink at `/opt/homebrew/bin/local-agent` points to the project's `local-agent` script, so it works from any directory
- **Script resolution:** `local-agent` uses `readlink -f "$0"` to resolve symlinks back to the project directory, so config/venv paths always work regardless of where it's invoked from

## Configuration

### Models

| Model | Purpose | Context |
|-------|---------|---------|
| `deepseek-coder:6.7b-instruct` | Code editing (Aider) | 8192 tokens |
| `qwen3:8b` | General tasks (Goose) | 32768 tokens |

### Config Files

```
config/
├── .aider.conf.yml              # Aider CLI behavior
├── .aider.model.settings.yml    # Aider model settings (context window, etc.)
└── goose.yaml                   # Goose config (provider, model, extensions)
```

### Environment Variables (`.env`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `OLLAMA_API_BASE` | `http://127.0.0.1:11434` | Ollama API endpoint |
| `OLLAMA_HOST` | `127.0.0.1:11434` | Ollama host for Aider |
| `OLLAMA_CONTEXT_LENGTH` | `32768` | Context window for Goose (Ollama default is 4096, too low) |

## Troubleshooting

### Ollama not running

```bash
ollama serve
```

`local-agent` will also try to auto-start Ollama if it's not running.

### Model not found

```bash
ollama pull deepseek-coder:6.7b-instruct
ollama pull qwen3:8b
```

### Goose not found

```bash
brew install block-goose-cli
```

### Context window too short / truncated responses

For Aider: edit `config/.aider.model.settings.yml` and increase `num_ctx`.

For Goose: increase `OLLAMA_CONTEXT_LENGTH` in `.env` (requires more RAM).

### Goose tool calling errors

qwen3:8b supports tool calling natively. If you see tool errors, ensure:
1. `OLLAMA_CONTEXT_LENGTH=32768` is set in `.env`
2. Ollama is up to date: `brew upgrade ollama`

### Browser automation not working

The `browse` command requires Node.js for the Playwright MCP server:
```bash
node --version  # Must be installed
npx -y @playwright/mcp@latest  # Will be downloaded on first use
```

### Venv or aider issues

Re-run setup to recreate the venv:

```bash
rm -rf .venv
./setup.sh
```

### "aider: command not found"

Make sure the venv is activated. `local-agent` handles this automatically, but if running aider directly:

```bash
source .venv/bin/activate
aider --config config/.aider.conf.yml --model-settings-file config/.aider.model.settings.yml
```

## Project Structure

```
Premison/
├── .claude/
│   ├── settings.json                # Claude Code project settings
│   └── settings.local.json          # Claude Code local overrides
├── commands/
│   ├── analyze.sh                   # Repo analysis sub-command
│   ├── fix-tests.sh                 # Test fixing sub-command
│   ├── implement.sh                 # Feature implementation sub-command
│   └── refactor.sh                  # Code refactoring sub-command
├── config/
│   ├── .aider.conf.yml              # Aider CLI config
│   ├── .aider.model.settings.yml    # Aider model settings
│   └── goose.yaml                   # Goose config (Ollama provider, extensions)
├── .env                             # Environment variables (Ollama connection, context length)
├── .gitignore                       # Excludes .venv, .env, caches, etc.
├── setup.sh                         # One-time installer
├── local-agent                      # Main CLI entry point
└── README.md                        # This file
```

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

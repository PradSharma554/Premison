#!/usr/bin/env bash
# fix-tests.sh — Auto-detect test runner, run tests, and fix failures using aider
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

# Auto-detect test runner
detect_test_runner() {
  if [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.cfg" ]]; then
    echo "pytest"
  elif [[ -f "go.mod" ]]; then
    echo "go test ./..."
  elif [[ -f "package.json" ]]; then
    echo "npm test"
  elif [[ -f "Makefile" ]] && grep -q "^test:" Makefile 2>/dev/null; then
    echo "make test"
  else
    echo ""
  fi
}

TEST_CMD=$(detect_test_runner)

if [[ -z "$TEST_CMD" ]]; then
  echo "Error: Could not detect test runner. Supported: pytest, go test, npm test, make test"
  exit 1
fi

echo "Detected test runner: $TEST_CMD"
echo "Running tests..."

# Run tests and capture output
TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1) || true
EXIT_CODE=${PIPESTATUS[0]:-$?}

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "All tests pass. Nothing to fix."
  exit 0
fi

echo "Tests failed. Passing failures to aider for fixing..."

aider \
  --config "$SCRIPT_DIR/config/.aider.conf.yml" \
  --model-settings-file "$SCRIPT_DIR/config/.aider.model.settings.yml" \
  --no-auto-commits \
  --message "The following test command failed: $TEST_CMD

Test output:
$TEST_OUTPUT

Please analyze the test failures and fix the code so all tests pass. Only modify source files, not test files, unless the tests themselves are clearly buggy."

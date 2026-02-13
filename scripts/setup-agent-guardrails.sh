#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  setup-agent-guardrails.sh --target <target-repo> [--source <templates-dir>] [--force]

Options:
  --target   Path to target Git repository (required)
  --source   Path to templates directory (default: ../templates from this script)
  --force    Overwrite existing files
  -h, --help Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../templates"
TARGET_REPO=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_REPO="${2:-}"
      shift 2
      ;;
    --source)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET_REPO" ]]; then
  echo "Error: --target is required." >&2
  usage
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: source templates dir not found: $SOURCE_DIR" >&2
  exit 1
fi

if [[ ! -d "$TARGET_REPO" ]]; then
  echo "Error: target repo path not found: $TARGET_REPO" >&2
  exit 1
fi

if ! git -C "$TARGET_REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: target is not a Git repository: $TARGET_REPO" >&2
  exit 1
fi

copy_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" && "$FORCE" -ne 1 ]]; then
    echo "SKIP   $dst (exists, use --force to overwrite)"
    return
  fi

  cp "$src" "$dst"
  echo "COPY   $dst"
}

copy_file "$SOURCE_DIR/AGENT_EXECUTION_CONTRACT.md" "$TARGET_REPO/AGENT_EXECUTION_CONTRACT.md"
copy_file "$SOURCE_DIR/AGENTS.md" "$TARGET_REPO/AGENTS.md"
copy_file "$SOURCE_DIR/CLAUDE.md" "$TARGET_REPO/CLAUDE.md"
copy_file "$SOURCE_DIR/AGENT_KICKOFF_PROMPT.md" "$TARGET_REPO/AGENT_KICKOFF_PROMPT.md"
copy_file "$SOURCE_DIR/.github/copilot-instructions.md" "$TARGET_REPO/.github/copilot-instructions.md"
copy_file "$SOURCE_DIR/.githooks/pre-commit" "$TARGET_REPO/.githooks/pre-commit"
copy_file "$SOURCE_DIR/.githooks/pre-push" "$TARGET_REPO/.githooks/pre-push"

chmod +x "$TARGET_REPO/.githooks/pre-commit" "$TARGET_REPO/.githooks/pre-push" 2>/dev/null || true

git -C "$TARGET_REPO" config core.hooksPath .githooks
echo "SET    git config core.hooksPath .githooks"
echo "DONE   Guardrail bootstrap complete for: $TARGET_REPO"

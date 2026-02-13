#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  setup-agent-guardrails.sh --target <target-repo> [--guardrails <on|off>] [--source <templates-dir>] [--force]

Options:
  --target   Path to target Git repository (required)
  --guardrails
             Guardrails mode: on (default) or off
  --source   Path to templates directory (default: ../templates from this script)
  --force    Overwrite existing files
  -h, --help Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../templates"
TARGET_REPO=""
FORCE=0
GUARDRAILS="on"

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
    --guardrails)
      GUARDRAILS="${2:-}"
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

if [[ "$GUARDRAILS" != "on" && "$GUARDRAILS" != "off" ]]; then
  echo "Error: --guardrails must be 'on' or 'off'." >&2
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

if [[ "$GUARDRAILS" == "off" ]]; then
  if git -C "$TARGET_REPO" config --get core.hooksPath >/dev/null 2>&1; then
    git -C "$TARGET_REPO" config --unset core.hooksPath
    echo "SET    git config --unset core.hooksPath"
  else
    echo "INFO   Guardrails already disabled (core.hooksPath not set)."
  fi
  echo "DONE   Guardrails OFF for: $TARGET_REPO"
  exit 0
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: source templates dir not found: $SOURCE_DIR" >&2
  exit 1
fi

MANIFEST="$SOURCE_DIR/install-manifest.txt"
if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: install manifest not found: $MANIFEST" >&2
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

while IFS= read -r relpath || [[ -n "$relpath" ]]; do
  relpath="${relpath#"${relpath%%[![:space:]]*}"}"
  relpath="${relpath%"${relpath##*[![:space:]]}"}"
  [[ -z "$relpath" || "${relpath:0:1}" == "#" ]] && continue

  copy_file "$SOURCE_DIR/$relpath" "$TARGET_REPO/$relpath"
done < "$MANIFEST"

chmod +x "$TARGET_REPO/.githooks/pre-commit" "$TARGET_REPO/.githooks/pre-push" 2>/dev/null || true

git -C "$TARGET_REPO" config core.hooksPath .githooks
echo "SET    git config core.hooksPath .githooks"
echo "DONE   Guardrails ON for: $TARGET_REPO"

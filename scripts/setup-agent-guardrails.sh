#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  setup-agent-guardrails.sh --target <target-repo> [--guardrails <on|off>] [--source <templates-dir>] [--force]
  setup-agent-guardrails.sh  # interactive mode

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

interactive_mode() {
  echo "Interactive mode."
  read -r -p "Enable guardrails? (y/n): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    GUARDRAILS="on"
  elif [[ "$yn" =~ ^[Nn]$ ]]; then
    GUARDRAILS="off"
  else
    echo "CANCEL User cancelled guardrails setup."
    exit 0
  fi

  read -r -p "Target Git repository path: " TARGET_REPO
  if [[ -z "$TARGET_REPO" ]]; then
    echo "CANCEL No repo selected."
    exit 0
  fi

  if [[ "$GUARDRAILS" == "on" ]]; then
    read -r -p "Templates folder [$SOURCE_DIR]: " source_input
    if [[ -n "$source_input" ]]; then
      SOURCE_DIR="$source_input"
    fi

    read -r -p "Overwrite existing files? (y/n): " yn_force
    if [[ "$yn_force" =~ ^[Yy]$ ]]; then
      FORCE=1
    fi
  fi
}

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
  interactive_mode
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
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "INFO   Source templates dir not found; skipping hook removal."
    echo "DONE   Guardrails OFF for: $TARGET_REPO"
    exit 0
  fi

  MANIFEST="$SOURCE_DIR/install-manifest.txt"
  if [[ ! -f "$MANIFEST" ]]; then
    echo "INFO   Install manifest not found; skipping hook removal."
    echo "DONE   Guardrails OFF for: $TARGET_REPO"
    exit 0
  fi

  while IFS= read -r relpath || [[ -n "$relpath" ]]; do
    relpath="${relpath#"${relpath%%[![:space:]]*}"}"
    relpath="${relpath%"${relpath##*[![:space:]]}"}"
    [[ -z "$relpath" || "${relpath:0:1}" == "#" ]] && continue
    [[ "$relpath" != .githooks/* ]] && continue

    src="$SOURCE_DIR/$relpath"
    hook_name="${relpath#.githooks/}"
    dest="$TARGET_REPO/.git/hooks/$hook_name"
    agent_hook="$TARGET_REPO/.git/hooks/agent-guardrails-$hook_name"
    orig="$TARGET_REPO/.git/hooks/$hook_name.orig"

    if [[ -f "$dest" ]]; then
      if grep -q "agent-guardrails-$hook_name" "$dest" 2>/dev/null; then
        if [[ -f "$orig" ]]; then
          mv "$orig" "$dest"
          echo "RESTORE $dest"
        else
          rm -f "$dest"
          echo "REMOVE $dest"
        fi
      elif [[ -f "$src" ]] && cmp -s "$src" "$dest"; then
        rm -f "$dest"
        echo "REMOVE $dest"
      else
        echo "SKIP   $dest (exists, not a guardrails hook)"
      fi
    fi

    if [[ -f "$agent_hook" && -f "$src" ]]; then
      if cmp -s "$src" "$agent_hook"; then
        rm -f "$agent_hook"
        echo "REMOVE $agent_hook"
      fi
    fi
  done < "$MANIFEST"

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

# Dispatcher + installer helpers for hook merging/backups
create_dispatcher() {
  local dest="$1"
  local hookname
  hookname="$(basename "$dest")"
  mkdir -p "$(dirname "$dest")"

  printf '%s\n' "#!/usr/bin/env bash" "set -euo pipefail" "HOOKDIR=\"\$(dirname \"\$0\")\"" "\"\$HOOKDIR/agent-guardrails-$hookname\" \"\$@\" || exit \$?" "if [ -x \"\$HOOKDIR/$hookname.orig\" ]; then" "  \"\$HOOKDIR/$hookname.orig\" \"\$@\" || exit \$?" "fi" "exit 0" > "$dest"
  chmod +x "$dest"
}

install_hook() {
  local src="$1" dst="$2" force="$3"
  local hookname agent_hook orig
  hookname="$(basename "$dst")"
  agent_hook="$(dirname "$dst")/agent-guardrails-$hookname"
  orig="$dst.orig"

  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" ]]; then
    if cmp -s "$src" "$dst"; then
      # destination already matches template; ensure agent copy exists
      cp "$src" "$agent_hook"
      chmod +x "$agent_hook"
      echo "COPY   $agent_hook"
      return
    fi

    if [[ ! -f "$orig" ]]; then
      mv "$dst" "$orig"
      echo "BACKUP $orig"
    else
      echo "INFO   backup exists: $orig"
    fi
  fi

  cp "$src" "$agent_hook"
  chmod +x "$agent_hook"
  echo "COPY   $agent_hook"

  create_dispatcher "$dst"
  echo "DISPATCH $dst"
}

while IFS= read -r relpath || [[ -n "$relpath" ]]; do
  relpath="${relpath#"${relpath%%[![:space:]]*}"}"
  relpath="${relpath%"${relpath##*[![:space:]]}"}"
  [[ -z "$relpath" || "${relpath:0:1}" == "#" ]] && continue

  if [[ "$relpath" == .githooks/* ]]; then
    src="$SOURCE_DIR/$relpath"
    dst="$TARGET_REPO/.git/hooks/${relpath#.githooks/}"
    install_hook "$src" "$dst" "$FORCE"
  else
    copy_file "$SOURCE_DIR/$relpath" "$TARGET_REPO/$relpath"
  fi
done < "$MANIFEST"

chmod +x "$TARGET_REPO/.git/hooks/pre-commit" "$TARGET_REPO/.git/hooks/pre-push" 2>/dev/null || true
echo "DONE   Guardrails ON for: $TARGET_REPO"

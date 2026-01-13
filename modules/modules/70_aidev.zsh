 # Dev copilot (sandbox only)

# --------------------------------------------------
# Model call helper (one place to tune prompt behavior)
# --------------------------------------------------
_ai_ollama_dev() {
  local tmp="$1"
  local task="$2"
  local mem="$3"
  local pers="$4"
  local context="$5"

  ollama run codellama:7b-instruct "
You are a cautious local coding copilot.

IMPORTANT: You must output ONLY a runnable zsh script that starts with #!/bin/zsh. No explanations, no markdown, no extra text.
If you output anything other than a runnable zsh script starting with #!/bin/zsh, the proposal will be discarded.

OUTPUT:
- ONLY a runnable zsh script
- Must start with #!/bin/zsh
- Write ONLY inside $AI_ROOT
- NEVER use absolute paths like /Users/... anywhere in output
- Do NOT use mktemp, /tmp, or any system temp directories
- NEVER write to /tmp, /var, /var/folders, or mktemp paths
- Prefer paths like: \$AI_ROOT/... (NOT ~ or \$HOME)
- Idempotent
- No markdown, no commentary

MEMORY:
$mem

PERSONALITY:
$pers

CONTEXT:
$context

TASK:
$task" > "$tmp"
}

aidev() {
  [ $# -eq 0 ] && { echo 'Usage: ai dev \"build something\"'; return 1; }

  local MEM CONTEXT tmp slug out
  MEM="$(sed -n '1,200p' "$AI_MEM_FILE" 2>/dev/null || true)"

  CONTEXT=$(cd "$AI_ROOT" && {
    echo "ROOT: $AI_ROOT"
    echo
    echo "LS:"
    ls -la | head -100
    echo
    echo "FILES:"
    find . -maxdepth 3 -type f | head -200
    echo
    echo "GIT:"
    git status -sb 2>/dev/null || true
  })

  # Temp file INSIDE sandbox (avoid mktemp + /var/folders)
  tmp="$AI_ROOT/.ai_proposals/.tmp_$$.$RANDOM.zsh"
  : > "$tmp" || { echo "Failed to create temp file: $tmp"; return 2; }

  slug="$(echo "$*" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g' | sed -E 's/^_+|_+$//g' | cut -c1-40)"
  out="$(aipath "${slug:-proposal}")"

  # personality text is optional; keep it cheap + safe
  local PERS
  PERS="$(aipersonality 2>/dev/null || true)"

  _ai_ollama_dev "$tmp" "$*" "$MEM" "$PERS" "$CONTEXT"

  # If the model forgot the shebang, retry once (format-only retry)
  if ! head -n 1 "$tmp" | grep -q '^#!/bin/zsh'; then
    _ai_log "DEV" "missing shebang; retrying once"
    _ai_ollama_dev "$tmp" "$*" "$MEM" "$PERS" "$CONTEXT"
  fi

  # Normalize any hard-coded sandbox path to literal $AI_ROOT (run AFTER final generation)
  if grep -Fq "$AI_ROOT" "$tmp" 2>/dev/null; then
    sed -i '' 's|'"$AI_ROOT"'|\$AI_ROOT|g' "$tmp"
  fi
  # Normalize redirections to always target $AI_ROOT (bare/./quoted filenames)
  sed -i '' -E \
    's|(>+)[[:space:]]*(["'"'"']?)(\./)?([A-Za-z0-9._-]+)\2|\1 "$AI_ROOT/\4"|g' \
    "$tmp"
  # Ensure shebang is present (hard guarantee)
  if ! head -n 1 "$tmp" | grep -q '^#!/bin/zsh'; then
    sed -i '' '1s|^|#!/bin/zsh\n|' "$tmp"
    _ai_log "DEV" "shebang auto-inserted"
  fi
  # Normalize touch of bare filenames into $AI_ROOT (supports multiple args)
  # Rewrites: touch a b "./c" 'd'  -> touch "$AI_ROOT/a" "$AI_ROOT/b" "$AI_ROOT/c" "$AI_ROOT/d"
  sed -i '' -E \
    '/^[[:space:]]*touch[[:space:]]+/ s|(^[[:space:]]*touch[[:space:]]+)|\1|g' \
    "$tmp"
  sed -i '' -E \
    '/^[[:space:]]*touch[[:space:]]+/ s|([[:space:]]+)(["'"'"']?)(\./)?([A-Za-z0-9._-]+)\2|\1"$AI_ROOT/\4"|g' \
    "$tmp"

  # 🔒 Preflight validation BEFORE saving
  if ! _ai_preflight_validate "$tmp"; then
    _ai_log "DEV" "preflight failed"
    rm -f "$tmp"
    return 3
  fi

  mv "$tmp" "$out"
  chmod +x "$out"

  echo "✅ Proposal saved:"
  echo "$out"
  echo "Next: aiprops | aishow $(basename "$out") | aiapply $(basename "$out")"
}
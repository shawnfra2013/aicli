 # Validation + apply

# 🔒 Extra safety checks before execution
_aiapply_safety_scan() {
  local file="$1"
  local root_ere
  root_ere="$(_ai_escape_ere "$AI_ROOT")"

  # must be a script
  if ! head -n 1 "$file" | grep -q '^#!/bin/zsh'; then
    echo "❌ Refusing to execute."
    echo "This proposal is NOT a runnable zsh script (missing #!/bin/zsh)."
    echo
    echo "Review it instead:"
    echo "  aishow $(basename "$file")"
    return 2
  fi

  # block obvious foot-guns (simple heuristics)
  if grep -nE '(^|[[:space:];])sudo([[:space:];]|$)|rm[[:space:]]+-rf|rm[[:space:]]+-fr|shutdown|reboot|launchctl[[:space:]]+unload|diskutil[[:space:]]+erase|mkfs|:(){:|:&};:' "$file" >/dev/null 2>&1; then
    echo "❌ Refusing to execute."
    echo "Proposal contains a blocked command pattern (sudo/rm -rf/shutdown/etc)."
    echo "Review it carefully:"
    echo "  sed -n '1,220p' \"$file\""
    return 3
  fi

  # require sandbox-only writes (heuristic):
  # allow: expanded $AI_ROOT path, literal $AI_ROOT/${AI_ROOT} (quoted or not), /dev/null, and ./ relative paths
  local write_pat allow_pat

  write_pat='(>|\|\s*tee\b|\btee\b|\bcp\b|\bmv\b|\bmkdir\b|\btouch\b|\bchmod\b|\bchown\b|\bchgrp\b|\brm\b)'
  allow_pat="($root_ere|\\\$AI_ROOT|\\\${AI_ROOT}|\"\\\$AI_ROOT\"|'\\\$AI_ROOT'|\"\\\${AI_ROOT}\"|'\\\${AI_ROOT}'|/dev/null|\\./)"

  if grep -nE "$write_pat" "$file" \
    | grep -vE '^[[:space:]]*#' \
    | grep -vE '<<' \
    | grep -vE "$allow_pat" >/dev/null 2>&1; then

    if [ -n "${AI_DEBUG:-}" ]; then
      echo "🔎 DEBUG: write-like lines that triggered rejection:"
      grep -nE "$write_pat" "$file" \
        | grep -vE '^[[:space:]]*#' \
        | grep -vE "$allow_pat" \
        | head -50
    fi

    echo "❌ Refusing to execute."
    echo "Proposal appears to write outside the sandbox ($AI_ROOT)."
    echo "If this is intentional, edit the proposal to target only $AI_ROOT."
    echo "Review:"
    echo "  sed -n '1,260p' \"$file\""
    return 4
  fi

  return 0
}

# --------------------------------------------------
# aivalidate — main validator (used by preflight + apply)
# --------------------------------------------------
aivalidate() {
  local explain=0
  local file

  if [ "$1" = "--explain" ]; then
    explain=1
    shift
  fi

  file="$1"
  [ -z "$file" ] && { echo "Usage: aivalidate [--explain] <file>"; return 2; }
  [ ! -f "$file" ] && { echo "Not found: $file"; return 2; }

  if [ "$explain" -eq 1 ]; then
    _aiapply_safety_scan "$file"
    return $?
  else
    _aiapply_safety_scan "$file" >/dev/null 2>&1
    return $?
  fi
}

aiapply() {
  local f="$1"
  [ -z "$f" ] && { echo 'Usage: aiapply <file>'; return 1; }

  local p="$AI_ROOT/.ai_proposals/$f"
  [ ! -f "$p" ] && { echo "Not found: $p"; return 1; }

  # 🔒 HARD SAFETY CHECKS
  _aiapply_safety_scan "$p" || return $?

  echo "Preview (first 200 lines):"
  sed -n '1,200p' "$p"
  echo
  read -r "ans?Apply this proposal? (yes/no): "
  [ "$ans" != "yes" ] && { echo "Canceled."; return 0; }

  (cd "$AI_ROOT" && /bin/zsh "$p")
}

# --------------------------------------------------
# Preflight proposal validation (before save)
# --------------------------------------------------
_ai_preflight_validate() {
  local tmp="$1"

  # Must be a runnable zsh script
  if ! head -n 1 "$tmp" | grep -q '^#!/bin/zsh'; then
    echo "❌ Proposal missing shebang (#!/bin/zsh)."
    return 1
  fi

  # Reuse the main validator in read-only mode
  if ! aivalidate "$tmp" >/dev/null 2>&1; then
    echo "❌ Proposal failed sandbox validation:"
    aivalidate --explain "$tmp"
    return 1
  fi

  return 0
}
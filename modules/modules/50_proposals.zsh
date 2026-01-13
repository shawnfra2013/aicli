# Proposal helpers

aiprops() {
  ls -lah "$AI_ROOT/.ai_proposals" 2>/dev/null || echo "No proposals."
}

aishow() {
  local f="$1"
  [ -z "$f" ] && { echo 'Usage: aishow <file>'; return 1; }
  sed -n '1,300p' "$AI_ROOT/.ai_proposals/$f"
}

aipath() {
  local n
  n=$(ls "$AI_ROOT/.ai_proposals" 2>/dev/null | awk -F_ '{print $1}' | sort -n | tail -1)
  [[ -z "$n" ]] && n=0
  n=$((10#$n + 1))
  printf "%s/.ai_proposals/%03d_%s.zsh" "$AI_ROOT" "$n" "${1:-proposal}" \
    | tr ' ' '_' | tr -cd '[:alnum:]_./-'
}
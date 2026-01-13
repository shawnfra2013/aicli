# Repo personality (optional)

aipersonality() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
  [ -f "$root/.ai/personality.md" ] && sed -n '1,200p' "$root/.ai/personality.md"
}
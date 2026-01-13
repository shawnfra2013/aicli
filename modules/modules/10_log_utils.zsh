 # Logging + helpers

_ai_log() {
  local evt="$1"; shift
  printf "[%s] %-10s %s\n" \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$evt" \
    "$*" >> "$AI_LOG_FILE"
}

_ai_sha256() {
  shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

_ai_escape_ere() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\./\\\.}"
  s="${s//\*/\\\*}"
  s="${s//\+/\\\+}"
  s="${s//\?/\\\?}"
  s="${s//\^/\\\^}"
  s="${s//\$/\\\$}"
  s="${s//\[/\\\[}"
  s="${s//\]/\\\]}"
  s="${s//\(/\\\(}"
  s="${s//\)/\\\)}"
  s="${s//\{/\\\{}"
  s="${s//\}/\\\}}"
  s="${s//\|/\\\|}"
  printf "%s" "$s"
}
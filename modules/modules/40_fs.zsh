# Filesystem helper

aifs() {
  [ $# -eq 0 ] && { echo 'Usage: ai fs "question"'; return 1; }

  local PWD_NOW LS_OUT DF_OUT
  PWD_NOW="$(pwd)"
  LS_OUT="$(ls -la 2>/dev/null | head -200)"
  DF_OUT="$(df -h . 2>/dev/null | head -20)"

  ollama run codellama:7b-instruct "
You are a cautious macOS filesystem assistant.

RULES:
- NEVER suggest deleting Documents/Desktop/Pictures/Music/Movies blindly.
- NEVER suggest deleting system paths (/System, /Library, /usr, /bin, etc).
- Prefer inspection commands (du, ls, find).
- Ask before anything destructive.

PWD:
$PWD_NOW

LS:
$LS_OUT

DISK:
$DF_OUT

TASK:
$*"
}
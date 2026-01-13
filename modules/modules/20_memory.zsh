# Memory

aimemo() {
  case "$1" in
    add)
      shift
      [ $# -eq 0 ] && { echo 'Usage: ai memo add "text"'; return 1; }
      printf "\n## %s\n- %s\n" "$(date '+%Y-%m-%d %H:%M')" "$*" >> "$AI_MEM_FILE"
      echo "✅ Memory added."
      _ai_log "MEMO" "add: $*"
      ;;
    show)
      sed -n '1,200p' "$AI_MEM_FILE"
      ;;
    edit)
      ${EDITOR:-nano} "$AI_MEM_FILE"
      ;;
    *)
      echo "Usage:"
      echo "  ai memo add \"remember this\""
      echo "  ai memo show"
      echo "  ai memo edit"
      ;;
  esac
}
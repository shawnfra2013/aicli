# Core paths + required files/dirs

export AI_ROOT="${AI_ROOT:-$HOME/ai-sandbox}"
typeset -g AI_MEM_FILE="$AI_ROOT/.ai_memory.md"

mkdir -p "$AI_ROOT" "$AI_ROOT/.ai_proposals" "$AI_ROOT/.ai_web_cache" "$AI_ROOT/.ai_logs"
touch "$AI_MEM_FILE"

# Audit log (inside sandbox)
typeset -g AI_LOG_FILE="$AI_ROOT/.ai_logs/ai.log"
touch "$AI_LOG_FILE"
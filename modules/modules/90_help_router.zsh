# Self-help commands (read-only) + main router

aiwhere() {
  echo "AI_ROOT:      $AI_ROOT"
  echo "Proposals:    $AI_ROOT/.ai_proposals"
  echo "Memory:       $AI_MEM_FILE"
  echo "Web cache:    $AI_ROOT/.ai_web_cache"
  echo "Config file:  $HOME/.config/aicli/ai.zsh"
}

aidoctor() {
  echo "AI Doctor (sanity checks)"
  echo "------------------------"
  command -v ollama >/dev/null 2>&1 && echo "✅ ollama: $(command -v ollama)" || echo "❌ ollama not found (install Ollama first)"
  [ -d "$AI_ROOT" ] && echo "✅ AI_ROOT exists: $AI_ROOT" || echo "❌ AI_ROOT missing: $AI_ROOT"
  [ -d "$AI_ROOT/.ai_proposals" ] && echo "✅ proposals dir ok" || echo "❌ proposals dir missing"
  [ -f "$AI_MEM_FILE" ] && echo "✅ memory file ok: $AI_MEM_FILE" || echo "❌ memory file missing"
  [ -d "$AI_ROOT/.ai_web_cache" ] && echo "✅ web cache dir ok" || echo "❌ web cache dir missing"

  if command -v ollama >/dev/null 2>&1; then
    ollama list 2>/dev/null | head -20 | sed 's/^/ℹ️  /'
  fi
}

aihelp() {
  local topic="${1:-}"
  case "$topic" in
    dev)
      cat <<'EOF'
ai dev — sandbox builder (proposal-only)

  ai dev "task"          creates a proposal script in:
                         ~/ai-sandbox/.ai_proposals/NNN_<slug>.zsh

  aiprops               list proposals
  aishow <file>          view proposal (safe)
  aiapply <file>         execute proposal ONLY if it starts with #!/bin/zsh

Safety:
  - Proposals must be scripts (shebang required)
  - aiapply refuses to run docs/markdown/text
EOF
      ;;
    memo)
      cat <<'EOF'
ai memo — local memory

  ai memo add "note"     append a timestamped note
  ai memo show           print first ~200 lines
  ai memo edit           open in $EDITOR (defaults to nano)

Stored at:
  ~/ai-sandbox/.ai_memory.md
EOF
      ;;
    web)
      cat <<'EOF'
ai web / fetch / read — gated web workflow

  ai web "topic"         suggests search queries + trusted domains (no fetching)
  ai fetch <url>          fetches ONLY allowlisted domains, saves to:
                         ~/ai-sandbox/.ai_web_cache/<timestamp>.txt
  ai read <file>          summarizes a local file safely

Allowlist (current):
  - docs.python.org
  - nodejs.org
  - docs.docker.com
  - brew.sh
  - github.com
  - stackoverflow.com
EOF
      ;;
    all|"")
      cat <<'EOF'
AI CLI commands

Core:
  ai "question"          general assistant
  ai fs "question"       filesystem helper (pwd/ls/df context)
  ai dev "task"          create sandbox proposal script (does NOT run it)
  ai memo ...            memory commands
  ai web "topic"         suggest sources/search queries (no fetching)
  ai fetch <url>          fetch allowlisted URL into web cache
  ai read <file>          summarize a local file safely

Proposal workflow:
  aiprops               list proposals
  aishow <file>          view proposal safely
  aiapply <file>         run proposal ONLY if it starts with #!/bin/zsh

Self-help:
  ai help [dev|memo|web] show help by topic
  ai where              show paths
  ai doctor             sanity checks (ollama, dirs, files)

Paths:
  AI_ROOT:     ~/ai-sandbox
  proposals:   ~/ai-sandbox/.ai_proposals
  memory:      ~/ai-sandbox/.ai_memory.md
  web cache:   ~/ai-sandbox/.ai_web_cache
  config file: ~/.config/aicli/ai.zsh
EOF
      ;;
    *)
      echo "Unknown help topic: $topic"
      echo "Try: ai help | ai help dev | ai help memo | ai help web"
      return 1
      ;;
  esac
}

# --------------------------------------------------
# Main router
# --------------------------------------------------
ai() {
  [ $# -eq 0 ] && { aihelp; return 1; }

  case "$1" in
    help|-h|--help) shift; aihelp "$@";;
    where) aiwhere;;
    doctor) aidoctor;;
    fs) shift; aifs "$@";;
    dev) shift; aidev "$@";;
    memo) shift; aimemo "$@";;
    web) shift; aiweb "$@";;
    fetch) shift; aifetch "$@";;
    read) shift; airead "$@";;
    *)
      if [ -t 0 ]; then
        ollama run codellama:7b-instruct "Be concise. Prefer commands.

TASK:
$*"
      else
        local input
        input="$(cat)"
        ollama run codellama:7b-instruct "Summarize input safely.

INPUT:
$input"
      fi
      ;;
  esac
}
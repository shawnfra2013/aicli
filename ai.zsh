 # ~/.config/aicli/ai.zsh
# AI CLI bootstrap loader (modular)

typeset -g AICLI_DIR="$HOME/.config/aicli"
typeset -g AICLI_MOD_DIR="$AICLI_DIR/modules"

# Load modules in numeric order
for f in "$AICLI_MOD_DIR"/*.zsh; do
  [ -f "$f" ] && source "$f"
done
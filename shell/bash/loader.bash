# Bash loader, sourced from ~/.bashrc after ~/.config/dotfiles/env.
. "$DF_ROOT/shell/common/loader.sh"
[ -f "$DF_ACTIVE/prompt/post.bash" ] && . "$DF_ACTIVE/prompt/post.bash"
[ -f ~/.fzf.bash ] && . ~/.fzf.bash

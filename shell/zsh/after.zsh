# Last in the zsh chain (after prompt and plugin framework).
command -v atuin >/dev/null && eval "$(atuin init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

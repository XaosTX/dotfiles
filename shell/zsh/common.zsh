# Zsh settings shared by every plugin framework. Sourced by shell/zsh/loader.zsh.

# codeangler helpers that need zsh syntax
function src() {
  local file
  if [[ "$1" ]]; then
    source "$DF_ROOT/shell/lib/$1.sh"
  else
    for file in "$DF_ROOT"/shell/lib/*; do source "$file"; done
  fi
}
# Run the bootstrap, then reload the shell helpers.
function dotfiles() {
  "$DF_ROOT/bootstrap.sh" "$@" && src
}

TERM=xterm-256color
fpath=(/usr/local/share/zsh-completions $fpath)
autoload datetime

# completion (compinstall output, trimmed)
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit

# history and line editing
HISTFILE=~/.zsh_history
setopt append_history share_history inc_append_history hist_find_no_dups hist_ignore_all_dups extended_history
setopt autocd extendedglob notify transient_rprompt
bindkey -v

# bash-completion scripts and tool completions (each only when installed)
[ -f "/etc/bash_completion.d/ssh" ] && . /etc/bash_completion.d/ssh
(( $+commands[kitty] )) && kitty + complete setup zsh | source /dev/stdin
(( $+commands[grafanactl] )) && eval "$(grafanactl completion zsh)"
(( $+commands[jira] )) && eval "$(jira completion zsh)"
(( $+commands[op] )) && eval "$(op completion zsh)"; (( $+commands[op] )) && compdef _op op
(( $+commands[bw] )) && eval "$(bw completion --shell zsh)"; (( $+commands[bw] )) && compdef _bw bw

# bash-my-aws / bash-my-op (guarded by their own file checks)
source "$DF_ROOT/shell/zsh/bma.zsh"
source "$DF_ROOT/shell/zsh/bmo.zsh"

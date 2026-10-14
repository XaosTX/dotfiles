# Bash-only stuff
if [ ! -z "$BASH" ]; then
  # vi mode in bash
  set -o vi

  # Case-insensitive globbing (used in pathname expansion)
  shopt -s nocaseglob

  # Check the window size after each command and, if necessary,
  # update the values of LINES and COLUMNS.
  shopt -s checkwinsize

  # tmux (bash only as oh-my-zsh has tmux plugin)

  function tmux_new_session() {
    tmux new-session -s "$1"
  }
  function tmux_attach() {
    tmux attach -t "$1"
  }
  function tmux_attach_d() {
    tmux attach -d -t "$1"
  }
  function tmux_kill_session() {
    tmux kill-session -t "$1"
  }

  alias ta="tmux_attach"
  alias tad="tmux_attach_d"
  alias ts="tmux_new_session"
  alias tl="tmux list-sessions"
  alias tksv="tmux kill-server"
  alias tkss="tmux_kill_session"
fi

export GREP_OPTIONS='--color=auto'

# Recursive grep with colors
function grepr() {
  grep --color=always -R "$@" | less
}

# Prevent less from clearing the screen while still showing colors.
export LESS=-XR

# SSH auto-completion based on entries in known_hosts.
if [ ! -z "$BASH" ] && [[ -e ~/.ssh/known_hosts ]]; then
  complete -o default -W "$(cat ~/.ssh/known_hosts | sed 's/[, ].*//' | sort | uniq | grep -v '[0-9]')" ssh scp sftp
fi

# thefuck
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"

# Wtf aren't these in my path already???
export PATH=$PATH:$HOME/Library/Python/3.7/bin


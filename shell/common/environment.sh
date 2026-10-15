# ~/.environment: executed by the command interpreter for login shells.
# common environment variables across shells
# put shell specific values in e.g. ~/.zsh/environment
export DF_DEBUG="${DF_DEBUG:-}"
if [ -n "$DF_DEBUG" ]; then echo "DEBUG: loading environment"; fi

export EDITOR=vim
export VISUAL=vim

if [ -x "$(which less)" ];then
  export PAGER=less
else
  export PAGER=more
fi

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

export INPUTRC=~/.inputrc
export SVDIR="$HOME/service"
# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# vim: filetype=sh
CLICOLOR=1

# functions to make PATH manipulatino easier
prepend_path() {
  if [ -d "$1" ]; then
    export PATH="$1:$PATH"
  fi
}
append_path() {
  if [ -d "$1" ]; then
    export PATH="$PATH:$1"
  fi
}

# set PATH so it includes system local bin if it exists
prepend_path "/usr/local/bin"

# Homebrew: use the first install found, and let brew set its own PATH (shellenv).
# Order: Apple Silicon, Intel, non-admin tarball (~/homebrew), non-admin git clone (~/.homebrew),
# Linuxbrew (system, then user), and the old ~/local/homebrew location.
for p in /opt/homebrew /usr/local "$HOME/homebrew" "$HOME/.homebrew" /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew" "$HOME/local/homebrew"; do
  if [ -x "$p/bin/brew" ]; then
    eval "$("$p/bin/brew" shellenv)"
    DF_BREW_PREFIX="$p"
    break
  fi
done

# set PATH so it includes user's private bin if it exists
prepend_path "$HOME/bin"

# set PATH so it includes user's private bin if it exists
prepend_path "$HOME/.local/bin"

# ANYENV settings
append_path "$HOME/.anyenv/bin"

# GO settings
#export GOPATH=$HOME/go/bin
if [ -n "$GOPATH" ]; then
  append_path "$GOPATH/bin"
fi
#append_path "/usr/local/go/bin"

# RUST settings
append_path "$HOME/.cargo/bin"

# Setup for OnlyKey GnuPG
#export GNUPGHOME=~/.gnupg/onlykey

# asdf: shims (every version set with asdf) and, when asdf is not already on PATH, the git-clone
# binary. Sets PATH only: asdf.sh is bash-only and breaks zsh, so it is never sourced here.
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
if [ -d "$ASDF_DATA_DIR/shims" ]; then prepend_path "$ASDF_DATA_DIR/shims"; fi
if ! command -v asdf >/dev/null 2>&1 && [ -x "$ASDF_DATA_DIR/bin/asdf" ]; then
  prepend_path "$ASDF_DATA_DIR/bin"
fi

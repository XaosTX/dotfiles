# ~/.commonrc: common settings for non-login shells.
if [ -n "$DEBUG" ]; then echo "DEBUG: loading ~/.commonrc"; fi
if [ -f "$DF_ROOT/shell/common/environment.sh" ]; then . "$DF_ROOT/shell/common/environment.sh"; fi
if [ -f "$DF_ROOT/shell/common/aliases.sh" ]; then . "$DF_ROOT/shell/common/aliases.sh"; fi

#==========================================================
# If not running interactively, don't do anything
#==========================================================
case $- in
    *i*) ;;
      *) return;;
esac
#==========================================================

#==========================================================
# Command History Settings
#==========================================================
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000
HISTTIMEFORMAT="%F %T "
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignorespace:erasedups
HISTIGNORE='ls:bg:fg:history'
#==========================================================

#==========================================================
# Base16 Shell
#==========================================================
BASE16_SCHEME="isotope"
BASE16_SHELL="$HOME/.config/base16-shell/scripts/base16-$BASE16_SCHEME.sh"
if [ -s $BASE16_SHELL ]; then . $BASE16_SHELL; fi
#==========================================================

export LESS='--quit-if-one-screen --ignore-case --status-column --LONG-PROMPT --RAW-CONTROL-CHARS --HILITE-UNREAD --tabs=4 --no-init --window=-4'

command -v anyenv >/dev/null && eval "$(anyenv init -)"
command -v rbenv >/dev/null && eval "$(rbenv init -)"

export PATH=$RBENV_ROOT/shims:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#==========================================================
# Log everything to files
#==========================================================
#smart_script
#==========================================================


# Editor: codeangler flavour (mvim on macOS outside SSH, quick-edit aliases for this repo).
if [[ ! "$SSH_TTY" ]] && is_osx; then
  export EDITOR='mvim -v'
  export LESSEDIT='mvim ?lm+%lm -- %f'
  alias vim="$EDITOR"
  alias vi="$EDITOR"
else
  export EDITOR='vim'
fi

export VISUAL="$EDITOR"
alias q="$EDITOR"
alias qv="q $DF_ROOT/variants/vim/plug/vimrc $DF_ROOT/os/darwin/gvimrc +'cd $DF_ROOT'"
alias qs="q $DF_ROOT"

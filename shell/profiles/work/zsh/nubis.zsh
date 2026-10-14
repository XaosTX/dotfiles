#export PASS_PROFILE_SUBDIR=Aws/<account>
[ -x ~/.rbenv/bin/rbenv ] && eval "$(~/.rbenv/bin/rbenv init - zsh)"
export PATH=~/.rbenv/bin:$PATH
if (( $+commands[nubis] ))
then
    eval "$(nubis eval)"
fi

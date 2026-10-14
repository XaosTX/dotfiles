# zsh-plugins: prezto (codeangler). Loaded from ~/.zprezto (install/optional/common/50_prezto.sh).
# Environment and settings carried over from the codeangler .zshenv, .zprofile and .zshrc.
# Secrets are not kept here (the Hugging Face token was removed from the public copy; rotate it).
# Machine paths use $HOME. The employer aliases are not in the repo.

#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

### VirtualEnvWrapper ###
# install virtualenvwrapper using `pip3 install virtualenvwrapper`
# export VIRTUALENVWRAPPER_PYTHON="$(brew --prefix)/bin/python3"
# uv
export PATH="$HOME/.local/bin:$PATH"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

#
# Executes commands at login pre-zshrc.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

#
# Editors
#

export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'

#
# Language
#

if [[ -z "$LANG" ]]; then
  export LANG='en_US.UTF-8'
fi

#
# Paths
#

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that cd searches.
# cdpath=(
#   $cdpath
# )

# Set the list of directories that Zsh searches for programs.
path=(
  /usr/local/{bin,sbin}
  $path
)

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

autoload bashcompinit && bashcompinit

#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# zmodload zsh/zprof

# Custom completions dir (populate with: uv generate-shell-completion zsh > ~/.zsh/completions/_uv)
fpath=(~/.zsh/completions $fpath)

# Source Prezto.
if [[ -s "$HOME/.zprezto/init.zsh" ]]; then
  source "$HOME/.zprezto/init.zsh"
fi

# Customize to your needs...
#
PATH=$PATH:/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin

[ -s "$HOME/.zaliases" ] && source "$HOME/.zaliases"

if asdf current java > /dev/null 2>&1
then
    export JAVA_HOME=$(asdf where java)
fi

## Golang

export GOPATH=$HOME/go
export GOROOT="/opt/homebrew/opt/go/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

## Java
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"

# -------------------------------
# Python
# -------------------------------

# Prevent accidental global pip installs
export PIP_REQUIRE_VIRTUALENV=true

# UV shell completion
# uv completions: run once to generate → mkdir -p ~/.zsh/completions && uv generate-shell-completion zsh > ~/.zsh/completions/_uv

# export VIRTUAL_ENV_DISABLE_PROMPT=1
# create syspip workaround
syspip2(){
  PIP_REQUIRE_VIRTUALENV=false pip2 "$@"
}
syspip3(){
  PIP_REQUIRE_VIRTUALENV=false uv pip "$@"
}

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

# Show UV project in prompt
function virtualenv_info {
    if [ -f "pyproject.toml" ] || [ -f ".python-version" ]; then
        echo '(uv) '
    elif [ $VIRTUAL_ENV ]; then
        echo '('`basename $VIRTUAL_ENV`') '
    fi
}

export PATH="$HOME/.local/bin:$PATH"


# compinit handled by zprezto completion module


## Homebrew
export PATH="/opt/homebrew/sbin:$PATH"


# . /opt/homebrew/opt/asdf/libexec/asdf.sh
# . /opt/homebrew/Cellar/asdf/0.16.2/bin/asdf.sh
# . ~/.asdf/plugins/dotnet/set-dotnet-env.zsh
# export ASDF_DIR="$HOME/.asdf"
# . "$HOME/.asdf/asdf.sh"

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/bin:$PATH"


# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Pin gcloud to homebrew Python — avoids asdf shim version thrash rebuilding virtenv
export CLOUDSDK_PYTHON=/opt/homebrew/bin/python3

# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
# gcloud bin already on PATH via path.zsh.inc above

# HuggingFace read token — required for pyannote diarization (therapy-tools pipeline).
# To rotate: revoke old + create new (read scope) at https://huggingface.co/settings/tokens
# then replace the value below and run: source ~/.zshrc

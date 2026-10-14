# Aliases for every shell. Shell-specific files live in shell/zsh and shell/bash;
# choice-driven aliases (ls, editor, gr) live in variants/; work aliases in shell/profiles/work.
if [ -n "$DEBUG" ]; then echo "DEBUG: loading aliases"; fi

# colour support for grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias .......="cd ../../../../../.."
alias mkdir="mkdir -pv"
mcd () {
    mkdir -p $1
    cd $1
}

alias fhere="find . -name "

# Zip
alias tarz='tar czvf'
# Unzip
alias taru='tar xzvf'

# Add confirmation when losing files
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias ag='alias | grep'
alias histg="history | grep"

alias ducks='du -cks * | sort -rn | head'
alias du="du -ach | sort -h"

alias ps="ps auxf"
if [[ $OSTYPE == "darwin"* ]]; then
  alias ps="ps aux"
fi
alias psg="ps | grep -v grep | grep -i -e VSZ -e"
alias free="free -mt"

alias wget="wget -c"
alias top="htop"

alias myip="curl http://ifconfig.co"

alias s='sudo'

alias vall="find | sort | vim - '+set nomod | map <buffer><C-M> :1000sp <cfile><C-M>'"
alias today='date +%Y-%m-%d'

# list all "Host" and "HostName" lines, then remove the strings: "Host " and "HostName "
alias sshhosts="grep -w -i -E 'Host|HostName' ~/.ssh/config | sed 's/Host //' | sed 's/HostName //'"

getcert() {
  echo | openssl s_client -showcerts -servername "$1" -connect "$1":443 2>/dev/null | openssl x509 -inform pem -noout -text
}

histstats() {
  history | awk '{CMD[$4]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n10
}

ffont() {
    fc-list | grep -i $1 | cut -d: -f2-
}

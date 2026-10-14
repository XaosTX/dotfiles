## Operating System

alias ll='ls -al'

#alias ...=../..
#alias ....=../../..
#alias .....=../../../..
#alias ......=../../../../..
#alias 1='cd -'
#alias 2='cd -2'
#alias 3='cd -3'
#alias 4='cd -4'
#alias 5='cd -5'
#alias 6='cd -6'
#alias 7='cd -7'
#alias 8='cd -8'
#alias 9='cd -9'
#alias _=sudo
#alias afind='ack -il'
alias d='dirs -v | head -10'
alias history='fc -l 1'

# alias l='ls -lah'
# alias la='ls -lAh'
# alias ll='ls -l'
# alias ls='ls -G'
# alias lsa='ls -ltra'
# alias md='mkdir -p'

# alias please=sudo
# alias po=popd
# alias pu=pushd
# alias rd=rmdir
# alias run-help=man
# alias which-command=whence
# alias viewPorts='lsof -iTCP -sTCP:LISTEN -n -P'
# alias be='bundle exec'

## Git

#alias g=git
#alias ga='git add'
alias gaa='git add --all'
alias gaas='git add src/*'
alias gapa='git add --patch'

alias gb='git branch'
alias gba='git branch -a'
#alias gbda='git branch --merged | command grep -vE "^(\*|\s*master\s*$)" | command xargs -n 1 git branch -d'
alias gbl='git blame -b -w'
#alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
# alias gbs='git bisect'
# alias gbsb='git bisect bad'
# alias gbsg='git bisect good'
# alias gbsr='git bisect reset'
# alias gbss='git bisect start'
# alias gc='git commit -v'
# alias 'gc!'='git commit -v --amend'
# alias gca='git commit -v -a'
# alias 'gca!'='git commit -v -a --amend'
# # alias gcam='git commit -a -m'
alias gcm='git commit -m `$1`'
# alias gcm='git commit -n -m "`$1`'
# alias 'gcan!'='git commit -v -a -s --no-edit --amend'
alias gkb='git checkout -b'
# alias gcf='git config --list'
# alias gcl='git clone --recursive'
# alias gclean='git clean -fd'
alias gkm='git checkout master'
# alias gcmsg='git commit -m'
alias gko='git checkout'
# alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
# alias gcs='git commit -S'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdct='git describe --tags `git rev-list --tags --max-count=1`'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdw='git diff --word-diff'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gfo='git fetch origin'
# alias gg='git gui citool'
# alias gga='git gui citool --amend'
alias ggpull='git pull origin $(current_branch)'
# alias ggpur=ggu
alias ggpush='git push origin $(current_branch)'
alias ggsup='git branch --set-upstream-to=origin/$(current_branch)'
alias gignore='git update-index --assume-unchanged'
# alias gignored='git ls-files -v | grep "^[[:lower:]]"'
# alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'
# alias gk='\gitk --all --branches'
# alias gke='\gitk --all $(git log -g --pretty=format:%h)'
alias gpl='git pull'

alias glg='git log --stat --color'
alias glgg='git log --graph --color'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glgp='git log --stat --color -p'
alias glo='git log --oneline --decorate --color'

# alias globurl='noglob urlglobber '
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
# alias glol='git log --graph --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit'
# alias glola='git log --graph --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit --all'
# alias glp=_git_log_prettily
# alias glum='git pull upstream master'

# alias gm='git merge'
# alias gmom='git merge origin/master'
# alias gmt='git mergetool --no-prompt'
# alias gmtvim='git mergetool --no-prompt --tool=vimdiff'
# alias gmum='git merge upstream/master'

# alias gp='git push'
# alias gpd='git push --dry-run'
# alias gpoat='git push origin --all && git push origin --tags'
# alias gpristine='git reset --hard && git clean -dfx'
# alias gpu='git push upstream'
# alias gpv='git push -v'

# alias gr='git remote'
# alias gra='git remote add'

# alias grb='git rebase'
# alias grba='git rebase --abort'
# alias grbc='git rebase --continue'
# alias grbi='git rebase -i'
# alias grbm='git rebase master'
# alias grbs='git rebase --skip'

# alias grep='grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'

# alias grh='git reset HEAD'
# alias grhh='git reset HEAD --hard'

# alias grmv='git remote rename'
# alias grrm='git remote remove'
# alias grset='git remote set-url'
# alias grt='cd $(git rev-parse --show-toplevel || echo ".")'
# alias gru='git reset --'
# alias grup='git remote update'
# alias grv='git remote -v'
# alias gsb='git status -sb'
# alias gsd='git svn dcommit'
# alias gsi='git submodule init'
# alias gsps='git show --pretty=short --show-signature'
# alias gsr='git svn rebase'
# alias gss='git status -s'
alias gs='git status'

# alias gsta='git stash'
# alias gstaa='git stash apply'
# alias gstd='git stash drop'
# alias gstl='git stash list'
# alias gstp='git stash pop'
# alias gsts='git stash show --text'

# alias gsu='git submodule update'
# alias gts='git tag -s'
# alias gtv='git tag | sort -V'

# alias gunignore='git update-index --no-assume-unchanged'
# alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
# alias gup='git pull --rebase'
# alias gupv='git pull --rebase -v'
# alias gvt='git verify-tag'
alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -n -m "--wip-- $1"'
# function gwip() {
#     git add -A; git rm $(git ls-files --deleted) 2> /dev/null;
#     if [ -n "$1" ]
#     then
#         git commit -n -m "--WIP-- $1"
#     else
#         git commit -n -m "--WIP--"
#     fi
# }

alias therapy='code ~/Work/therapy-tools.code-workspace'

# Docker

alias di='docker images'
alias dlsv='docker volume ls -f dangling=true'
alias drmi='docker rmi -f'
alias drm='docker rm -f'
alias drm-all='docker rm $(docker ps -a -q)'
alias drmn='docker network rm'
alias drmv='docker volume rm $(docker volume ls -qf dangling=true)'
alias dps='docker ps -a'
alias dcp='docker cp'
alias dstop='docker stop'
alias dc='docker-compose'

#####  KUBERNETES  #####
# alias k="kubectl --insecure-skip-tls-verify"
alias k="kubectl"
alias kb="kubectl"
alias mk="minikube"
# alias box='ssh -i $HOME/.ssh/id_rsa casey.burnett@10.235.47.51'
alias bs='aws --no-verify-ssl'
alias t=terraform


alias java11="export JAVA_HOME=$JAVA_11_HOME"


# Personal

alias techlog="code $HOME/g/GitlabCom/Understanding/technology-journal-log/techlog-learning.code-workspace"
alias studies="cd $HOME/g/Studies"
alias trash="cd $HOME/g/Scratchpad"
alias bootstrap="code $HOME/bootstrap/tools/bootstrap.code-workspace"
alias weather="curl wttr.in/80301;"
alias tinyscripts="cd $HOME/g/GitLabCom/Understanding/technology-journal-log/tinyscripts"
pi() {
    export GOOGLE_CLOUD_PROJECT=claude-codeassist-p-ebum
    export GOOGLE_CLOUD_LOCATION=us-east5
    command npx pi "@"
}



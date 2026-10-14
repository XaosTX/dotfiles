if [ -f ~/.bash-my-op/aliases ]; then 
  export PATH="$PATH:$HOME/.bash-my-op/bin"
  source ~/.bash-my-op/aliases

  # For ZSH users, uncomment the following two lines:
  autoload -U +X compinit && compinit
  autoload -U +X bashcompinit && bashcompinit

  source ~/.bash-my-op/bash_completion.sh
fi

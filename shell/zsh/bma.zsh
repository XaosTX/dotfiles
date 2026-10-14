if [ -f ~/.bash-my-aws/aliases ]; then 
  export PATH="$PATH:$HOME/.bash-my-aws/bin"
  source ~/.bash-my-aws/aliases

  # For ZSH users, uncomment the following two lines:
  autoload -U +X compinit && compinit
  autoload -U +X bashcompinit && bashcompinit

  source ~/.bash-my-aws/bash_completion.sh
fi

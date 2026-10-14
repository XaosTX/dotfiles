# zsh plugins: oh-my-zsh (codeangler). Theme is powerlevel9k only when that prompt is chosen.
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [[ ! -d $ZSH ]]; then
  print -u2 "dotfiles: oh-my-zsh not found at $ZSH (run install/50_zsh.sh, or choose zinit)"
else
  if [[ "$DF_PROMPT" == "powerlevel9k" ]]; then
    ZSH_THEME="powerlevel9k/powerlevel9k"
  else
    ZSH_THEME=""
  fi
  CASE_SENSITIVE="true"
  ZSH_DISABLE_COMPFIX=true
  plugins=(git tmux vi-mode)
  source "$ZSH/oh-my-zsh.sh"
fi

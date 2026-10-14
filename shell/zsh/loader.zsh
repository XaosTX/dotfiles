# Ordered zsh loader, sourced from ~/.zshrc after ~/.config/dotfiles/env.
DF_ACTIVE="${DF_ACTIVE:-$HOME/.config/dotfiles/active}"
export DOTFILES="$DF_ROOT"

source "$DF_ROOT/shell/common/loader.sh"     # env, aliases, helpers, variants, profile aliases
source "$DF_ROOT/shell/zsh/common.zsh"       # completions, history, src()/dotfiles()

for f in "$DF_ROOT"/shell/os/"$DF_OS"/*.zsh(N) "$DF_ROOT"/local/shell/*.zsh(N); do source "$f"; done

for pdir in "$DF_ROOT"/shell/profiles/*(N/); do
  p="${pdir:t}"
  [[ ",$DF_PROFILES," == *",$p,"* ]] || continue
  for f in "$pdir"/zsh/*.zsh(N); do source "$f"; done
done

# prompt -> plugin framework -> prompt post-init (order matters)
[[ -f $DF_ACTIVE/prompt/pre.zsh ]] && source "$DF_ACTIVE/prompt/pre.zsh"
[[ -f $DF_ACTIVE/zsh-plugins/init.zsh ]] && source "$DF_ACTIVE/zsh-plugins/init.zsh"
[[ -f $DF_ACTIVE/prompt/post.zsh ]] && source "$DF_ACTIVE/prompt/post.zsh"
source "$DF_ROOT/shell/zsh/after.zsh"

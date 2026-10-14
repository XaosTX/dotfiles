# Optional: oh-my-zsh and the powerlevel9k theme. zinit is the default plugin framework.
# Cloned at pinned commits, so updates are a deliberate change to these two lines.
OMZ_COMMIT=964ddf789b022b6958b27d02d7fa54f552de21e9      # ohmyzsh/ohmyzsh master, 2026-10-14
P9K_COMMIT=66d53c02476c6207f65b0d22910242abc68935e3      # Powerlevel9k/powerlevel9k master, 2026-10-14 (archived upstream)

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  e_header "Installing oh-my-zsh (pinned)"
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" && git -C "$HOME/.oh-my-zsh" checkout -q "$OMZ_COMMIT"
fi

P9K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel9k"
if [ -d "$HOME/.oh-my-zsh" ] && [ ! -d "$P9K_DIR" ]; then
  e_header "Installing powerlevel9k (pinned)"
  git clone https://github.com/Powerlevel9k/powerlevel9k.git "$P9K_DIR" && git -C "$P9K_DIR" checkout -q "$P9K_COMMIT"
fi

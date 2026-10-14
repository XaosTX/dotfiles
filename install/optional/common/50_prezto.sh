# Optional: prezto (zsh framework). Choose zsh-plugins=prezto and prompt=prezto to use it.
# Pinned to a commit; update the pin deliberately.
PREZTO_COMMIT=cff2d01871425b1b80710f8ec6a475c5a53145b4   # sorin-ionescu/prezto master, 2026-10-14

if [ ! -d "$HOME/.zprezto" ]; then
  e_header "Installing prezto (pinned)"
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto" && git -C "$HOME/.zprezto" checkout -q "$PREZTO_COMMIT" && git -C "$HOME/.zprezto" submodule update --init --recursive -q
fi

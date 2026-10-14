# Exit if Homebrew is not installed.
[[ ! "$(type -p brew)" ]] && e_error "Brew casks need Homebrew to install." && return 1

l0=(
  1password
  alfred
  divvy
  iterm2
)

# Homebrew casks
l1=(

  # Applications
  dash
  dropbox
  evernote
  google-chrome
  karabiner-elements
  postman
  slack
  sourcetree
  spotify
  sublime-text
  virtualbox
  whatsapp

  # Quick Look plugins (commented out)
  # qlcolorcode
  # qlmarkdown
  # qlprettypatch
  # qlstephen
  # quicklook-csv
  suspicious-package

)

# Compile array of casks to install based on installation level
for i in $(seq "$(get_install_type)" -1 0); do
  eval arr=("\${"l"$i[@]}")
  casks=("${casks[@]}" "${arr[@]}")
done

brew_install_casks

# Work around colorPicker symlink issue.
# https://github.com/caskroom/homebrew-cask/issues/7004
cps=()
for f in ~/Library/ColorPickers/*.colorPicker; do
  [[ -L "$f" ]] && cps=("${cps[@]}" "$f")
done

if (( ${#cps[@]} > 0 )); then
  e_header "Fixing colorPicker symlinks"
  for f in "${cps[@]}"; do
    target="$(readlink "$f")"
    e_arrow "$(basename "$f")"
    rm "$f"
    cp -R "$target" ~/Library/ColorPickers/
  done
fi

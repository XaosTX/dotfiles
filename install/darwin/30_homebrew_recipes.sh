# Exit if Homebrew is not installed.
[[ ! "$(type -p brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

# Homebrew recipes
l0=(
  cmake
  ctags
  fzf
  git
  git-extras
  grip
  icdiff
  jq
  jsonlint
  lesspipe
  macvim
  python
  rbenv
  ssh-copy-id
  the_silver_searcher
  thefuck
  tmux
  tree
  wget
  zsh
)

l1=(
  awscli
)

# Compile array of casks to install based on installation level
for i in $(seq "$(get_install_type)" -1 0); do
  eval arr=("\${"l"$i[@]}")
  recipes=("${recipes[@]}" "${arr[@]}")
done

brew_install_recipes

# Ubuntu-only stuff. Abort if not Ubuntu.
is_ubuntu || return 1

# Update APT.
e_header "Updating APT"
sudo apt-get -qq update
sudo apt-get -qq dist-upgrade

# Install APT packages.
l0=(
  build-essential
  cmake
  gnome-shell
  jq
  pipx
  unzip
  libssl-dev
  python3-dev
  python3-pip
  tmux
  vim
  zsh
)

l1=(
  default-jdk
  zlib1g-dev
)

# Compile array of casks to install based on installation level
for i in $(seq "$(get_install_type)" -1 0); do
  eval arr=("\${"l"$i[@]}")
  packages=("${packages[@]}" "${arr[@]}")
done

packages=($(setdiff "${packages[*]}" "$(dpkg --get-selections | grep -v deinstall | awk '{print $1}')"))

if (( ${#packages[@]} > 0 )); then
  e_header "Installing APT packages: ${packages[*]}"
  for package in "${packages[@]}"; do
    sudo apt-get -qq install "$package"
  done
fi

# thefuck is not installed: it imports `imp` and `distutils`, which Python 3.12 (Ubuntu 24.04) removed.

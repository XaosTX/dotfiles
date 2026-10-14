# Nerd Fonts: SauceCode Pro Medium and Inconsolata Regular, from a pinned release.
# macOS installs to ~/Library/Fonts. Linux installs to ~/.local/share/fonts, then fc-cache.
DF_NERD_TAG=v3.5.1
DF_NERD_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/$DF_NERD_TAG"

df_font_dir() {
  if is_osx; then echo "$HOME/Library/Fonts"; else echo "$HOME/.local/share/fonts"; fi
}

# df_install_font ARCHIVE FILE: download the release archive, copy FILE into the font directory
df_install_font() {
  local archive="$1" file="$2" tmp dest
  dest="$(df_font_dir)/$file"
  if [ -e "$dest" ]; then e_arrow "font already installed: $file"; return 0; fi
  if ! command -v unzip >/dev/null 2>&1; then e_error "unzip is needed to install fonts"; return 1; fi
  tmp="$(mktemp -d)" || return 1
  if ! curl -fLso "$tmp/$archive" "$DF_NERD_BASE/$archive"; then
    e_error "download failed: $archive ($DF_NERD_TAG)"; rm -rf "$tmp"; return 1
  fi
  if ! unzip -qo "$tmp/$archive" "$file" -d "$tmp/x"; then
    e_error "$file not found in $archive"; rm -rf "$tmp"; return 1
  fi
  mkdir -p "$(df_font_dir)"
  cp "$tmp/x/$file" "$dest" && e_success "installed font: $file"
  rm -rf "$tmp"
}

df_install_font SourceCodePro.zip SauceCodeProNerdFont-Medium.ttf
df_install_font Inconsolata.zip InconsolataNerdFont-Regular.ttf

# Linux caches fonts per directory
if ! is_osx && command -v fc-cache >/dev/null 2>&1; then fc-cache -f "$(df_font_dir)"; fi

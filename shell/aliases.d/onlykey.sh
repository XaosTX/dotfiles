function ssho() {
  if command -v onlykey-agent >/dev/null && [ -n "$DF_PERSONAL_ONLYKEY_IDENTITY" ]; then
    onlykey-agent "$DF_PERSONAL_ONLYKEY_IDENTITY" -- ssh "$@"
  else
    /usr/bin/ssh "$@"
  fi
}

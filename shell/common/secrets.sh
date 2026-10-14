# Work secrets, read at shell load. DF_SECRETS (set by bootstrap.sh) picks the store:
#   local           -> DF_WORK_* values in ~/.config/dotfiles/settings.env (mode 600)
#   macos-keychain  -> the login keychain, item "dotfiles.<key>" (macOS only)
# df_secret KEY prints the value for KEY (jira-user, ops-pass-path), or nothing if it isn't set.
df_secret() {
  local var="DF_WORK_$(echo "$1" | tr 'a-z-' 'A-Z_')"
  if [ "${DF_SECRETS:-local}" = macos-keychain ]; then
    security find-generic-password -a "$USER" -s "dotfiles.$1" -w 2>/dev/null
  else
    eval "printf '%s' \"\${$var-}\""
  fi
}

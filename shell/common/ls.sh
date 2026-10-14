# ls: one function for both ls-aliases choices. Sourced after the choice files, so DF_LS_PREFER is set.
#   DF_LS_PREFER=lsd (xaostx) uses lsd when it is installed; otherwise the system ls.
# The binary and its colour flag are chosen once, here, not on every call. `command` skips
# this function, so it never calls itself.
if [ "${DF_LS_PREFER:-system}" = lsd ] && command -v lsd >/dev/null 2>&1; then
  DF_LS_CMD=(lsd)
else
  case "$OSTYPE" in
    darwin*) DF_LS_CMD=(ls -G) ;;       # BSD ls on macOS
    *) DF_LS_CMD=(ls --color=auto) ;;   # GNU ls
  esac
fi
ls() { command "${DF_LS_CMD[@]}" "$@"; }

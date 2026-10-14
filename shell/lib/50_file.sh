# Files will be created with these permissions:
# files 644 -rw-r--r-- (666 minus 022)
# dirs  755 drwxr-xr-x (777 minus 022)
umask 022


# File size
# File size (BSD stat on macOS, GNU stat elsewhere)
if [ "$DF_OS" = darwin ]; then
  alias fs="stat -f '%z bytes'"
else
  alias fs="stat -c '%s bytes'"
fi
alias df="df -h"

# Recursively delete `.DS_Store` files
alias dsstore="find . -name '*.DS_Store' -type f -ls -delete"


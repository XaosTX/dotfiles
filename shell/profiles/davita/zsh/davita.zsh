# Davita profile. Applies only on macOS hosts whose name starts with DVA-.
# Add settings here as they are discovered; the gate below keeps them off other machines.
if [[ "$DF_OS" == darwin && "$(hostname -s)" == DVA-* ]]; then
   :
fi

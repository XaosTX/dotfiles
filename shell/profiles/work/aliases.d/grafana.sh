# grafanactl config: macOS location first, then the XDG location used elsewhere.
DF_GRAFANA_CONF=""
for f in "$HOME/Library/Application Support/grafanactl/config.yaml" "${XDG_CONFIG_HOME:-$HOME/.config}/grafanactl/config.yaml"; do
  if [ -r "$f" ]; then DF_GRAFANA_CONF="$f"; break; fi
done
if [ -n "$DF_GRAFANA_CONF" ]; then
  export GRAFANA_SERVER=$(cat "$DF_GRAFANA_CONF" | grep 'server:' | cut -d: -f2- | xargs)
  export GRAFANA_TOKEN=$(cat "$DF_GRAFANA_CONF" | grep 'token:' | cut -d: -f2- | xargs)
fi

# Corporate TLS proxies (Zscaler and similar) re-sign HTTPS with a root from the keychain.
# The bootstrap writes every keychain certificate to this file; trust it in command-line tools.
DF_CA_BUNDLE="$HOME/.config/certs/macos-ca-bundle.pem"
if [[ -f $DF_CA_BUNDLE ]]; then
  export CURL_CA_BUNDLE=$DF_CA_BUNDLE SSL_CERT_FILE=$DF_CA_BUNDLE
  export NODE_EXTRA_CA_CERTS=$DF_CA_BUNDLE REQUESTS_CA_BUNDLE=$DF_CA_BUNDLE
  export AWS_CA_BUNDLE=$DF_CA_BUNDLE
fi

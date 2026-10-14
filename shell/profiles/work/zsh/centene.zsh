# Only execute if a Centene user is logged in
if [[ "$USER" == cn* ]]; then
   if [[ "$DF_OS" == darwin ]]; then
      #zScaler Credential Variables (macOS: certificates come from the System keychains)
      security find-certificate -a -p > ~/cacert-keychain.pem
      security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >> ~/cacert-keychain.pem
      export REQUESTS_CA_BUNDLE=${HOME}/cacert-keychain.pem
      export DEFAULT_CA_BUNDLE_PATH=${HOME}/cacert-keychain.pem

      #zScaler work around for command line apps
      proxy=$(grep -om 1 "127.0.0.1:9000/localproxy-.*\.pac" /Library/Preferences/SystemConfiguration/preferences.plist)
      export HTTP_PROXY=$proxy
      export HTTPS_PROXY=$proxy
      export NO_PROXY=localhost,127.0.0.1${DF_WORK_NO_PROXY_DOMAIN:+,*.$DF_WORK_NO_PROXY_DOMAIN}

      #node
      export NODE_EXTRA_CA_CERTS=${HOME}/cacert-keychain.pem

      #AWS CA bundle (macOS certificates)
      export AWS_CA_BUNDLE=${HOME}/cacert-keychain.pem
   fi

   #npm (portable)
   export NPM_CONFIG_USERCONFIG=${HOME}/.npmrc

   #AWS (portable)
   export AWS_CONFIG_FILE=${HOME}/.aws/config
   export AWS_SHARED_CREDENTIALS_FILE=${HOME}/.aws/credentials

   alias creds='~/ws/dce/SRE/scripts/aws/aws_credentials_helper.py'
fi

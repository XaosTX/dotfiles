# Work environment (no username gate; the certificate and proxy setup is in shell/os/darwin/proxy.zsh)

#npm (portable)
export NPM_CONFIG_USERCONFIG=${HOME}/.npmrc

#AWS (portable)
export AWS_CONFIG_FILE=${HOME}/.aws/config
export AWS_SHARED_CREDENTIALS_FILE=${HOME}/.aws/credentials

alias creds='~/ws/dce/SRE/scripts/aws/aws_credentials_helper.py'

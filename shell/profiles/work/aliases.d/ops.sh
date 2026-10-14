# Sign in to the password manager (1Password through pass). The path is a work secret (see install.sh).
_ops_pass_path="$(df_secret ops-pass-path)"
if [ -n "$_ops_pass_path" ]; then
  alias ops="eval \$(pass $_ops_pass_path | op signin)"
fi

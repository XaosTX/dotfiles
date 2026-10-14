# DEFERRED: the Dropbox key step is being reworked. No flag runs this file.
# Full installation only
[ "$(get_install_type)" -lt "1" ] && return 1

# Get dropbox token, retrying thrice for valid token
tries=0
while : ; do
  read -p "Dropbox access token: " -s token
  printf "\n"
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -I https://api.dropboxapi.com/2/files/list_folder --header "Authorization: Bearer ${token}")
  ([ "$status_code" -eq "401" ] && [ "$tries" -lt "2" ]) || break
  e_error "Invalid token!"
  tries=$[$tries+1]
done

# Bail if we couldn't get valid token
[ "$status_code" -eq "401" ] && return 1

# List ssh_keys using jq to map the json response to a space-delimited string, then convert to bash array
files=( $(curl -s -X POST https://api.dropboxapi.com/2/files/list_folder \
  --header "Authorization: Bearer ${token}" \
  --header 'Content-Type: application/json' \
  --data '{"path":"/dotfiles/ssh_keys"}' | jq '.entries | map(.path_lower) | join(" ")' | tr -d '"') )

# Bail if something went wrong
if [ "${#files[@]}" -eq 0 ]; then
  e_error "No keys found"
  return 1
fi

if [ ! -d ~/.ssh ]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
fi

# Decrypt keys to ~/.ssh
pushd ~/.ssh
for path in ${files[@]}; do

  file=$(basename $path)

  # Only process .enc files and skip existing ones
  ([[ ! $path =~ .*\.enc ]] || [ -e ~/.ssh/${file%.enc} ]) && continue

  # Download enc key
  curl -s -o $file -X POST https://content.dropboxapi.com/2/files/download \
    --header "Authorization: Bearer ${token}" \
    --header "Dropbox-API-Arg: {\"path\":\"${path}\"}"

  # Ask for encryption key the first time, attempt decryption, and retry a couple more times if it fails
  if [ -z $enckey ]; then
    tries=0
    while : ; do
      read -p "Private encryption key: " -s enckey
      printf "\n"
      decrypt $file $enckey &> /dev/null
      status_code="$?"
      ([ "$status_code" -ne "0" ] && [ "$tries" -lt "2" ]) || break
      e_error "Invalid encryption key!"
      tries=$[$tries+1]
    done

    # Bail if we couldn't get the right encryption key
    [ "$status_code" -ne "0" ] && break
  else
    decrypt $file $enckey
  fi

  e_arrow "Decrypted $file"

done

# Clean up
rm -rf *.enc

chmod 600 id_rsa*
chmod 644 *.pub

popd

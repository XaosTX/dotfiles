# Optional, disabled by default. Chef DK is end-of-life and this pipes a remote script into sudo bash. Fix before use.
# Full installation only
[ "$(get_install_type)" -lt "1" ] && return 1

# Install chef-dk for Ubuntu
is_ubuntu && curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -P chefdk

# Install chef gems
if [[ "$(type -p chef)" ]]; then
  chef gem install knife-ec2
  chef gem install knife-solo
fi

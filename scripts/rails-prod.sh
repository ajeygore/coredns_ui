#!/bin/bash


# Exit immediately if a command exits with a non-zero status
set -e

# ----------------------------
# Configuration Variables
# ----------------------------

# List of required environment variables
REQUIRED_VARS=("APP_PORT" "DEPLOY_USER")

# Function to check environment variables
check_env_vars() {
  local missing_vars=()
  
  for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
      missing_vars+=("$var")
    fi
  done
  
  if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "Error: The following environment variable(s) are not set: ${missing_vars[*]}"
    exit 1
  fi
}

# Check required environment variables
check_env_vars

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo apt-get install -y ansible wget curl rsync git libssl-dev libreadline-dev zlib1g-dev libffi-dev libffi8 build-essential libyaml-dev

# Install Ruby
if command -v ruby >/dev/null 2>&1; then
  INSTALLED_RUBY_VERSION=$(ruby -v | awk '{print $2}')
  echo "Ruby is installed. Version: $INSTALLED_RUBY_VERSION"

else
  echo "Ruby is not installed. Proceeding with installation."

  cd ~
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  sudo rm -rf ruby-3.3.4.tar ruby-3.3.4
  wget "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.4.tar.gz"
  tar -xzvf ruby-3.3.4.tar.gz
  cd ruby-3.3.4
  ./configure --disable-install-rdoc --enable-yjit --with-libffi-dir=/usr/lib/x86_64-linux-gnu
  make
  sudo make install
fi





# # No docker required yet
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc

# # Add the repository to Apt sources:
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt-get update
# sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


export NVM_DIR="$HOME/.nvm"
echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 20
npm install yarn -g

source ~/.bashrc

export GEM_HOME=~/.ruby/
export PATH="$PATH:~/.ruby/bin"

cd ~/coredns_ui


GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" ansible-playbook scripts/rails_prod.yml

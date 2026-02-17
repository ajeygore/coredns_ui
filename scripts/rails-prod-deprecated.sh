#!/bin/bash


# Exit immediately if a command exits with a non-zero status
set -e

# ----------------------------
# Configuration Variables
# ----------------------------

# List of required environment variables
REQUIRED_VARS=("APP_PORT" "DEPLOY_USER" "DEPLOY_PASSWORD")

export APP_PORT=8000
export DEPLOY_USER="deploy"
export DEPLOY_PASSWORD="deploy"

# Create user with home directory and bash shell, set password, add to sudo group
sudo useradd -m -s /bin/bash deploy && echo "deploy:$DEPLOY_PASSWORD" | sudo chpasswd && sudo usermod -aG sudo deploy

#Replace yourpassword with the actual password. If you want passwordless sudo as well:
echo 'deploy ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/deploy

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
sudo apt-get update -y
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
  . "$HOME/.cargo/env"
  sudo rm -rf ruby-3.3.4.tar ruby-3.3.4
  wget "https://cache.ruby-lang.org/pub/ruby/4.0/ruby-4.0.1.tar.gz"
  tar -xzvf ruby-4.0.1.tar.gz
  cd ruby-4.0.1
  ./configure --disable-install-rdoc --enable-yjit --with-libffi-dir=/usr/lib/x86_64-linux-gnu
  make
  sudo make install
fi


export NVM_DIR="$HOME/.nvm"
echo 'export GEM_HOME=~/.ruby/' >> ~/.bashrc
echo 'export PATH="$PATH:~/.ruby/bin"' >> ~/.bashrc

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 24.13.1
npm install yarn -g

source ~/.bashrc

export GEM_HOME=~/.ruby/
export PATH="$PATH:~/.ruby/bin"

cd ~/coredns_ui

GEM_HOME=~/.ruby/ PATH="$PATH:~/.ruby/bin" ansible-playbook scripts/rails-prod.yml

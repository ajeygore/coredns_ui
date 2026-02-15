#!/bin/bash
set -e

HOST=$1
ENV_FILE=${2:-.env}

if [ -z "$HOST" ]; then
  echo "Usage: ./setup.sh <user@host> [env-file]"
  echo ""
  echo "  user@host  SSH destination (e.g., deploy@192.168.1.10)"
  echo "  env-file   Path to .env file (default: .env)"
  echo ""
  echo "Examples:"
  echo "  ./setup.sh deploy@myserver.com .env.production"
  echo "  ./setup.sh root@10.0.0.5"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: env file '$ENV_FILE' not found"
  exit 1
fi

# Check for ansible
if ! command -v ansible-playbook &> /dev/null; then
  echo "Error: ansible is not installed. Install it with:"
  echo "  brew install ansible    # macOS"
  echo "  apt install ansible     # Ubuntu/Debian"
  exit 1
fi

# Parse user@host
if [[ "$HOST" == *@* ]]; then
  SSH_USER="${HOST%%@*}"
  SSH_HOST="${HOST#*@}"
else
  SSH_USER="$(whoami)"
  SSH_HOST="$HOST"
fi

echo "==> Deploying CoreDNS UI to ${SSH_HOST} as ${SSH_USER}"
echo "==> Using env file: ${ENV_FILE}"

# Copy env file to server
echo "==> Copying env file to server..."
scp "${ENV_FILE}" "${HOST}:/tmp/coredns-ui.env"

# Run ansible playbook
echo "==> Running deployment playbook..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ansible-playbook "${SCRIPT_DIR}/scripts/deploy.yml" \
  -i "${SSH_HOST}," \
  -u "${SSH_USER}" \
  -e "deploy_user=${SSH_USER}"

echo ""
echo "==> Deploy complete! Services running on ${SSH_HOST}:"
echo "    App:     http://${SSH_HOST}:3000"
echo "    CoreDNS: ${SSH_HOST}:53"

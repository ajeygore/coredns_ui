#!/bin/bash
set -e

usage() {
  echo "Usage: $0 -h <host> -u <deploy_user> -p <password> [-r <redis_host>]"
  echo
  echo "  -h  Remote host (IP or hostname)"
  echo "  -u  Deploy user to create on remote box"
  echo "  -p  Password for the deploy user"
  echo "  -r  Redis host (default: localhost)"
  exit 1
}

REDIS_HOST="localhost"

while getopts "h:u:p:r:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) DEPLOY_USER="$OPTARG" ;;
    p) DEPLOY_PASSWORD="$OPTARG" ;;
    r) REDIS_HOST="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$DEPLOY_USER" || -z "$DEPLOY_PASSWORD" ]]; then
  echo "Error: -h, -u, and -p are required."
  echo
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SSH multiplexing — reuse a single TCP connection for all Ansible tasks
export ANSIBLE_SSH_ARGS="-o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-ssh-%h-%p-%r -o StrictHostKeyChecking=no"
# Pipelining — send commands over the existing SSH connection instead of creating temp files
export ANSIBLE_PIPELINING=true

ansible-playbook "$SCRIPT_DIR/coredns-production.yml" \
  -i "$HOST," \
  -u root \
  --extra-vars "deploy_user=$DEPLOY_USER deploy_password=$DEPLOY_PASSWORD redis_host=$REDIS_HOST"

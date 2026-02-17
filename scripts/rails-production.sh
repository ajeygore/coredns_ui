#!/bin/bash
set -e

usage() {
  echo "Usage: $0 -h <host> -u <deploy_user> -p <password> -P <port>"
  echo
  echo "  -h  Remote host (IP or hostname)"
  echo "  -u  Deploy user to create on remote box"
  echo "  -p  Password for the deploy user"
  echo "  -P  Application port (Puma)"
  exit 1
}

while getopts "h:u:p:P:" opt; do
  case $opt in
    h) HOST="$OPTARG" ;;
    u) DEPLOY_USER="$OPTARG" ;;
    p) DEPLOY_PASSWORD="$OPTARG" ;;
    P) APP_PORT="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$HOST" || -z "$DEPLOY_USER" || -z "$DEPLOY_PASSWORD" || -z "$APP_PORT" ]]; then
  echo "Error: All four arguments are required."
  echo
  usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ansible-playbook "$SCRIPT_DIR/rails-production.yml" \
  -i "$HOST," \
  -u root \
  --extra-vars "deploy_user=$DEPLOY_USER deploy_password=$DEPLOY_PASSWORD puma_port=$APP_PORT"

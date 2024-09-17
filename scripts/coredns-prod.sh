#!/bin/bash


# Exit immediately if a command exits with a non-zero status
set -e

export DEPLOY_USER=`whoami`
sudo mkdir -p /etc/coredns
ansible-playbook scripts/coredns-prod.yml

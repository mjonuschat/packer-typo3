#!/bin/bash
set -eo pipefail

apt-get update
apt-get dist-upgrade -y

echo "Rebooting the machine..."
reboot
sleep 60

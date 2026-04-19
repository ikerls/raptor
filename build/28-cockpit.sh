#!/usr/bin/bash

set -eoux pipefail

echo "Installing Cockpit..."

dnf5 install -y cockpit \
cockpit-ostree \
cockpit-podman \
cockpit-selinux

systemctl enable cockpit.socket

echo "Cockpit installed successfully"

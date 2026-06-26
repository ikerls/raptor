#!/usr/bin/bash

set -eoux pipefail

echo "Installing Niri..."

dnf5 install -y --nogpgcheck \
  --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
  terra-release

# Niri + Noctalia + useful Niri desktop bits
dnf5 install -y \
  niri \
  noctalia-shell

echo "Niri installed successfully"

systemctl --global enable niri.service

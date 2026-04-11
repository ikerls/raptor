#!/usr/bin/bash

set -eoux pipefail

echo "Installing ProtonVPN..."

wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"

dnf5 install -y protonvpn-stable-release-1.0.3-1.noarch.rpm
dnf5 install -y proton-vpn-gnome-desktop

rm -f protonvpn-stable-release-1.0.3-1.noarch.rpm

echo "ProtonVPN installed successfully"

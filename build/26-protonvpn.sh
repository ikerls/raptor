#!/usr/bin/bash

set -eoux pipefail

echo "Installing ProtonVPN..."

wget "https://repo.protonvpn.com/fedora-$(cut -d' ' -f 3 /etc/fedora-release)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"

dnf5 install -y protonvpn-stable-release-1.0.3-1.noarch.rpm
dnf5 --setopt=tsflags=noscripts install -y proton-vpn-gnome-desktop

rm -f protonvpn-stable-release-1.0.3-1.noarch.rpm

echo "ProtonVPN installed successfully"

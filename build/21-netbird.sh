#!/usr/bin/env bash

set -oue pipefail

### Install Netbird from Official Repository
echo "Installing Netbird..."

# Add Netbird RPM repository GPG key
rpm --import https://pkgs.netbird.io/yum/repodata/repomd.xml.key

# Add Netbird RPM repository
cat > /etc/yum.repos.d/netbird.repo << 'EOF'
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# Install Netbird
dnf5 --setopt=tsflags=noscripts install -y netbird

# Clean up repo file (required - repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/netbird.repo

echo "Netbird installed successfully"

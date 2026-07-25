#!/usr/bin/env bash

set -oue pipefail

### Install 1Password from Official Repository
echo "Installing 1Password..."

# Add 1Password RPM repository GPG key
rpm --import https://downloads.1password.com/linux/keys/1password.asc

# Add 1Password RPM repository
cat >/etc/yum.repos.d/1password.repo <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# Pre-create the groups as system groups before the RPM scriptlet runs.
cat >/usr/lib/sysusers.d/1password.conf <<'EOF'
g onepassword -
g onepassword-mcp -
g onepassword-cli -
EOF
systemd-sysusers /usr/lib/sysusers.d/1password.conf

# Satisfy the rpm-ostree /usr/local -> /var/usrlocal layout.
mkdir -p /var/usrlocal/bin

# Install 1Password
dnf5 install -y 1password 1password-cli

# Clean up repo file (required - repos don't work at runtime in bootc images)
rm -f /etc/yum.repos.d/1password.repo

echo "1Password installed successfully"

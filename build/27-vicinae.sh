#!/usr/bin/bash

set -eoux pipefail

echo "Installing Vicinae..."

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

copr_install_isolated "quadratech188/vicinae" \
    vicinae

systemctl enable vicinae
echo "Vicinae installed successfully"

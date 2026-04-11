#!/usr/bin/bash

set -eoux pipefail

echo "Installing Helium..."

source /ctx/build/copr-helpers.sh

copr_install_isolated "imput/helium" \
    helium-bin

echo "Helium installed successfully"

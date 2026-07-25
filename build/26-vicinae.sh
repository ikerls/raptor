#!/usr/bin/bash

set -eoux pipefail

echo "Installing Vicinae..."

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

# cmark-gfm dependency from quadratech188/cmark-gfm
copr_install_isolated "quadratech188/cmark-gfm" \
    cmark-gfm

# vicinae from quadratech188
copr_install_isolated "quadratech188/vicinae" \
    vicinae

echo "Vicinae installed successfully"

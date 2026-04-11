#!/usr/bin/bash

set -eoux pipefail

echo "Installing Niri..."

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 -y install \
    niri \
    wl-clipboard \
    qt6-qtmultimedia \
    cargo \
    rust

copr_install_isolated "avengemedia/danklinux" \
    cliphist \
    dgop \
    dsearch \
    matugen \
    quickshell

copr_install_isolated "avengemedia/dms" \
    dms


echo "Niri installed successfully"

systemctl --global add-wants niri.service dms dsearch.service

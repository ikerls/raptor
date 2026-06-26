#!/usr/bin/bash

set -eoux pipefail

echo "Installing Niri..."

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

dnf5 -y install \
    niri

dnf5 -y install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" terra-release

dnf5 -y install noctalia-shell

echo "Niri installed successfully"

systemctl --global add-wants niri.service dms dsearch.service

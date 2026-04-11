#!/usr/bin/bash

set -eoux pipefail

echo "Installing Alacritty..."

dnf5 install -y alacritty

echo "Alacritty installed successfully"

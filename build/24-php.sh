#!/usr/bin/bash

set -eoux pipefail

echo "Installing PHP..."

dnf5 install -y php php-cli php-mysqlnd php-pgsql php-sqlite3 php-gd php-curl php-mbstring php-xml php-intl php-bcmath php-zip

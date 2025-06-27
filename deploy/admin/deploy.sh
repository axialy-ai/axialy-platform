#!/usr/bin/env bash
# deploy/admin/deploy.sh  – new file (chmod +x)
# Runs on the droplet via appleboy/ssh-action

set -euo pipefail

WEBROOT=/var/www/html

echo "🔄  Syncing application code to $WEBROOT …"
rsync -a --delete --exclude='admin.env' ./ "${WEBROOT}/"

if [[ -f admin.env ]]; then
  echo "📄  Installing environment file …"
  mv -f admin.env "${WEBROOT}/.env"
fi

chown -R www-data:www-data "${WEBROOT}"

echo "🔁  Reloading PHP-FPM and NGINX …"
systemctl reload php8.1-fpm
systemctl reload nginx

echo "✅  Admin deployment complete."

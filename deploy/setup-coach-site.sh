#!/usr/bin/env bash
# One-time setup for coach.nosait.com. Run once with sudo; afterwards new
# builds only need deploy/push-web.sh, which needs no privileges.
#
#   sudo bash ~/my-coach-deploy/setup-coach-site.sh
#
# Touches only paths belonging to this site. No existing site is read,
# modified, or restarted.
set -euo pipefail

DOMAIN="coach.nosait.com"
WEBROOT="/var/www/my-coach-web"
STAGING="/home/claude/my-coach-deploy/web"
CONF="/etc/nginx/sites-available/${DOMAIN}"

if [[ -e "$CONF" ]]; then
  echo "!! ${CONF} already exists — stopping so nothing gets overwritten."
  exit 1
fi

echo "==> Creating ${WEBROOT}"
mkdir -p "$WEBROOT"
# Owned by claude so future deploys rsync straight in without sudo;
# www-data only ever reads.
chown claude:claude "$WEBROOT"
chmod 755 "$WEBROOT"

echo "==> Copying the staged build"
rsync -a --delete "${STAGING}/" "${WEBROOT}/"
chown -R claude:claude "$WEBROOT"

echo "==> Installing the nginx site"
cp /home/claude/my-coach-deploy/coach.nosait.com.conf "$CONF"
ln -sfn "$CONF" "/etc/nginx/sites-enabled/${DOMAIN}"

echo "==> Testing the nginx config (aborts before reload if this fails)"
nginx -t

echo "==> Reloading nginx"
systemctl reload nginx

echo "==> Requesting the certificate"
# --nginx edits only this domain's server block. --redirect adds the
# HTTP->HTTPS redirect. Change the email before first run if you want
# expiry notices somewhere else.
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos \
  --redirect --email ahmedahmed.73555@gmail.com

echo
echo "Done. https://${DOMAIN} should now serve the app."

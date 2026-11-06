#!/usr/bin/env bash
# Push a new web build to coach.nosait.com. Run from the repo root on the dev
# machine, after `flutter build web --release` in frontend/.
#
#   bash deploy/push-web.sh
#
# No sudo: /var/www/my-coach-web is owned by claude after the one-time setup,
# so this writes into it directly.
#
# Uses tar over ssh rather than rsync — Git Bash on Windows ships no rsync.
# The remote side does have it, but the transfer has to work from here.
set -euo pipefail

HOST="claude@76.13.63.162"
KEY="${HOME}/.ssh/claude-agent"
LOCAL="frontend/build/web"
REMOTE="/var/www/my-coach-web"
STAGING="/home/claude/my-coach-deploy/web"

SSH=(ssh -i "$KEY" -o BatchMode=yes "$HOST")

if [[ ! -f "${LOCAL}/main.dart.js" ]]; then
  echo "!! ${LOCAL} is missing or incomplete."
  echo "   Run: cd frontend && flutter build web --release"
  exit 1
fi

echo "==> Local build: $(cat "${LOCAL}/version.json")"

# Upload to the home directory first. /var/www is root-owned, so claude cannot
# create a staging directory beside the live one — only the live directory
# itself belongs to us. Staging in $HOME keeps a slow transfer off the served
# tree entirely.
echo "==> Uploading to staging"
"${SSH[@]}" "rm -rf ${STAGING} && mkdir -p ${STAGING}"
tar -cz -C "$LOCAL" . | "${SSH[@]}" "tar -xz -C ${STAGING}"

# Local disk-to-disk rsync: only changed files move, so the window where the
# served tree is mid-update is a fraction of a second rather than the whole
# upload. --delete clears files dropped between builds.
echo "==> Syncing into the served directory"
"${SSH[@]}" "rsync -a --delete ${STAGING}/ ${REMOTE}/"

echo "==> Live: $("${SSH[@]}" "cat ${REMOTE}/version.json")"
echo "==> Done. Hard-refresh once; the service worker handles the rest."

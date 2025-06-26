#!/usr/bin/env bash
###############################################################################
#  infra/import_existing.sh
#  • Works in GitHub Actions or locally
#  • Discovers real DigitalOcean object IDs via doctl
#  • Imports only if the object actually exists
###############################################################################
set -euo pipefail

die() { echo "::error::$*"; exit 1; }

# Ensure doctl can talk to DO (token must already be in env)
doctl account get >/dev/null 2>&1 || die "doctl auth failed – check DIGITALOCEAN_TOKEN"

TF="terraform -chdir=$(dirname "$0")"

echo "🔎  Discovering DigitalOcean resources …"

# ─────────────────────────────────────────────────────────────────────────────
# Project (static – replace if you use a different project)
# ─────────────────────────────────────────────────────────────────────────────
PROJECT_ID="d895904a-4fbb-4492-8038-02071ab8f75b"
$TF import digitalocean_project.axialy "$PROJECT_ID"

# ─────────────────────────────────────────────────────────────────────────────
# Firewalls – look them up by NAME, not by hard-coded ID
# ─────────────────────────────────────────────────────────────────────────────
lookup_fw() {
  local name=$1
  doctl compute firewall list --output json | jq -r ".[] | select(.name==\"$name\") .id" | head -n1
}

FW_WEB_ID=$(lookup_fw  "axialy-web")
FW_DB_ID=$(lookup_fw   "axialy-db")

[ -n "$FW_WEB_ID" ] && $TF import digitalocean_firewall.web "$FW_WEB_ID" \
  || echo "⚠️  Firewall 'axialy-web' not found – skipping import"

[ -n "$FW_DB_ID" ] && $TF import digitalocean_firewall.db  "$FW_DB_ID"  \
  || echo "⚠️  Firewall 'axialy-db'  not found – skipping import"

# ─────────────────────────────────────────────────────────────────────────────
# Droplets – automatically match by tag "axialy"
# (change the tag or add specific names if you prefer)
# ─────────────────────────────────────────────────────────────────────────────
for droplet in $(
  doctl compute droplet list --tag-name axialy --no-header --format ID,Name |
  awk '{print $1":"$2}'
); do
  ID=${droplet%%:*}
  NAME=${droplet#*:}
  case $NAME in
    *root*)   RES=digitalocean_droplet.root  ;;
    *ui*)     RES=digitalocean_droplet.ui    ;;
    *api*)    RES=digitalocean_droplet.api   ;;
    *admin*)  RES=digitalocean_droplet.admin ;;
    *)        echo "⚠️  Unknown droplet '$NAME' – skipping"; continue ;;
  esac
  $TF import "$RES" "$ID"
done

echo "✅  Import phase finished."

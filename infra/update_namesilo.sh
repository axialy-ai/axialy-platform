#!/usr/bin/env bash
set -eo pipefail
API="https://www.namesilo.com/api"
KEY="$NAMESILO_API_KEY"
DOMAIN="$NAMESILO_DOMAIN"

# $1 = host ('' means apex), $2 = IP
upsert() {
  local HOST="$1" IP="$2"
  local EXISTING
  EXISTING=$(curl -s "$API/dnsListRecords?version=1&type=xml&key=$KEY&domain=$DOMAIN" \
           | xmllint --xpath "//resource_record[host='$HOST']/record_id/text()" - 2>/dev/null || true)

  if [ -n "$EXISTING" ]; then
    curl -s "$API/dnsUpdateRecord?version=1&type=xml&key=$KEY&domain=$DOMAIN&rrid=$EXISTING&rrhost=$HOST&rrvalue=$IP&rrttl=300" >/dev/null
  else
    curl -s "$API/dnsAddRecord?version=1&type=xml&key=$KEY&domain=$DOMAIN&rrtype=A&rrhost=$HOST&rrvalue=$IP&rrttl=300" >/dev/null
  fi
}

# read droplet IPs from terraform output
ROOT_IP=$(terraform -chdir=infra output -raw droplet_ips.root)
UI_IP=$(terraform -chdir=infra output -raw droplet_ips.ui)
API_IP=$(terraform -chdir=infra output -raw droplet_ips.api)
ADMIN_IP=$(terraform -chdir=infra output -raw droplet_ips.admin)

# apex + www  →  root droplet
upsert ""    "$ROOT_IP"
upsert "www" "$ROOT_IP"

# sub-sites
upsert "ui"    "$UI_IP"
upsert "api"   "$API_IP"
upsert "admin" "$ADMIN_IP"

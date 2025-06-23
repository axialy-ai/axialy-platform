#!/usr/bin/env bash
# Ensures each host ends with *exactly one* correct A-record
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

upsert () {                        # $1 = rrhost  $2 = IPv4
  local RRHOST="$1" IP="$2"

  local FILTER
  if [[ -z "$RRHOST" ]]; then
    FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    FILTER='.host=="'"$RRHOST.$DOMAIN"'"'
  fi

  # Delete *all* existing A-records for this host
  local IDS
  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and '"$FILTER"')
               | .record_id')
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done

  # Add the single desired record
  local HOST_PARAM
  if [[ -z "$RRHOST" ]]; then HOST_PARAM=""; else HOST_PARAM="rrhost=${RRHOST}&"; fi
  curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# Pull IPs from Terraform outputs
IPS_JSON=$(terraform -chdir=infra output -json droplet_ips)

upsert "admin" "$(echo "$IPS_JSON" | jq -r '.admin')"
upsert "ui"    "$(echo "$IPS_JSON" | jq -r '.ui')"
upsert "api"   "$(echo "$IPS_JSON" | jq -r '.api')"
upsert "www"   "$(echo "$IPS_JSON" | jq -r '.root')"
upsert ""      "$(echo "$IPS_JSON" | jq -r '.root')"   # apex

echo "✅  NameSilo DNS records are up-to-date."

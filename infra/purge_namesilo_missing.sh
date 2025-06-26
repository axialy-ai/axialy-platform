#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# purge_namesilo_missing.sh
# Keeps NameSilo’s A-records in lock-step with live DigitalOcean droplets.
# ---------------------------------------------------------------------------
set -euo pipefail

API="https://www.namesilo.com/api"
DOMAIN="${NAMESILO_DOMAIN:?NAMESILO_DOMAIN not set}"
KEY="${NAMESILO_API_KEY:?NAMESILO_API_KEY not set}"

echo "🔎  Fetching droplets from DigitalOcean…"
declare -A DROPLET_IP
doctl compute droplet list -o json |
  jq -r '.[] |
         [.name, (.networks.v4[] | select(.type=="public").ip_address)] |
         @tsv' |
  while IFS=$'\t' read -r NAME IP; do
    [[ -z "${DROPLET_IP[$NAME]+x}" ]] && DROPLET_IP["$NAME"]="$IP"
  done

echo "🔎  Reconciling NameSilo zone…"
declare -A RECORD_SEEN   # ensures we keep at most one A-record per host

curl -s "$API/dnsListRecords?version=1&type=json&key=$KEY&domain=$DOMAIN" |
  # ⬇️ convert “string OR array OR null” ➜ always an array
  jq -r '
    .reply.resource_record
    | (if type=="array"   then .
       elif type=="object" then [.]
       else [] end)
    | .[]
    | select(.type=="A")
    | [.record_id, .host, .value] | @tsv' |
  while IFS=$'\t' read -r ID HOST IP; do
    WANT_IP="${DROPLET_IP[$HOST]:-}"
    if [[ -n "$WANT_IP" && "$IP" == "$WANT_IP" && -z "${RECORD_SEEN[$HOST]+x}" ]]; then
      RECORD_SEEN["$HOST"]=1           # keep this one
    else
      echo "🗑️   Deleting $HOST → $IP"
      curl -s "$API/dnsDeleteRecord?version=1&type=json&key=$KEY&domain=$DOMAIN&rrid=$ID" >/dev/null
    fi
  done

# ---------------------------------------------------------------------------
# Add missing A-records
# ---------------------------------------------------------------------------
for HOST in "${!DROPLET_IP[@]}"; do
  if [[ -z "${RECORD_SEEN[$HOST]+x}" ]]; then
    RRHOST="${HOST%.$DOMAIN}"
    [[ "$RRHOST" == "$HOST" ]] && RRHOST="@"   # apex
    IP="${DROPLET_IP[$HOST]}"
    echo "➕  Adding  $HOST → $IP"
    curl -s \
      "$API/dnsAddRecord?version=1&type=json&key=$KEY&domain=$DOMAIN&rrtype=A&rrhost=$RRHOST&rrvalue=$IP&rrttl=3600" \
      >/dev/null
  fi
done

echo "✅  NameSilo zone exactly mirrors live droplets."

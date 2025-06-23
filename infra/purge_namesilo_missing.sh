#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# purge_namesilo_missing.sh
#
# 1.  Get *all* DigitalOcean droplets  ➜  map  DROPLET_IP[host]=ip
# 2.  Stream through every NameSilo A-record:
#       • keep it   → if IP matches DROPLET_IP[host] **and** we haven't kept one already
#       • delete it → otherwise (stale or duplicate)
# 3.  Add a new A-record for any droplet host that still has none.
# ---------------------------------------------------------------------------
set -euo pipefail

API="https://www.namesilo.com/api"
DOMAIN="${NAMESILO_DOMAIN:?NAMESILO_DOMAIN not set}"
KEY="${NAMESILO_API_KEY:?NAMESILO_API_KEY not set}"

echo "🔎  Fetching droplets from DigitalOcean…"
declare -A DROPLET_IP
doctl compute droplet list -o json |
  jq -r '.[] |
         [.name,
          (.networks.v4[] | select(.type=="public").ip_address)] |
         @tsv' |
  while IFS=$'\t' read -r NAME IP; do
    # record the first IP we see for a host; ignore any later duplicates
    [[ -z "${DROPLET_IP[$NAME]+x}" ]] && DROPLET_IP["$NAME"]="$IP"
  done

echo "🔎  Reconciling NameSilo zone…"
declare -A RECORD_SEEN   # flags to make sure we keep at most one per host

curl -s "$API/dnsListRecords?version=1&type=json&key=$KEY&domain=$DOMAIN" |
  jq -r '.reply.resource_record[]
         | select(.type=="A")
         | [.record_id, .host, .value] | @tsv' |
  while IFS=$'\t' read -r ID HOST IP; do
    WANT_IP="${DROPLET_IP[$HOST]:-}"
    if [[ -n "$WANT_IP" && "$IP" == "$WANT_IP" && -z "${RECORD_SEEN[$HOST]+x}" ]]; then
      # This is the one (and only) record we keep for this host
      RECORD_SEEN["$HOST"]=1
    else
      echo "🗑️   Deleting stale/duplicate  $HOST → $IP"
      curl -s "$API/dnsDeleteRecord?version=1&type=json&key=$KEY&domain=$DOMAIN&rrid=$ID" >/dev/null
    fi
  done

# ---------------------------------------------------------------------------
# Add missing records
# ---------------------------------------------------------------------------
for HOST in "${!DROPLET_IP[@]}"; do
  if [[ -z "${RECORD_SEEN[$HOST]+x}" ]]; then
    RRHOST="${HOST%.$DOMAIN}"
    [[ "$RRHOST" == "$HOST" ]] && RRHOST="@"   # apex
    IP="${DROPLET_IP[$HOST]}"
    echo "➕  Adding               $HOST → $IP"
    curl -s \
      "$API/dnsAddRecord?version=1&type=json&key=$KEY&domain=$DOMAIN&rrtype=A&rrhost=$RRHOST&rrvalue=$IP&rrttl=3600" \
      >/dev/null
  fi
done

echo "✅  NameSilo zone now exactly mirrors the current droplet set."

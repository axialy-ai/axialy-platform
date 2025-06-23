#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Purge NameSilo A-records that no longer map to an existing DigitalOcean
# droplet, then add any A-records that are missing.
#
# Requires:
#   - doctl (already installed earlier in the workflow)
#   - jq
#   - $NAMESILO_API_KEY  – NameSilo API key                  (env var)
#   - $NAMESILO_DOMAIN   – e.g. axialy.ai                    (env var)
# ---------------------------------------------------------------------------
set -euo pipefail

API="https://www.namesilo.com/api"
DOMAIN="${NAMESILO_DOMAIN:?NAMESILO_DOMAIN not set}"
KEY="${NAMESILO_API_KEY:?NAMESILO_API_KEY not set}"

##############################################################################
# 1. Gather live droplets  ➜  associative array  DROPLET_IPS[host]=ip
##############################################################################
echo "🔎 Fetching droplets from DigitalOcean…"
declare -A DROPLET_IPS

doctl compute droplet list -o json |
  jq -r '.[] |
         [.name,
          (.networks.v4[] | select(.type=="public").ip_address)]
         | @tsv' |
  while IFS=$'\t' read -r NAME IP; do
    DROPLET_IPS["$NAME"]="$IP"
  done

##############################################################################
# 2. Gather current NameSilo A-records
#       ➜ NS_IPS[host]=ip      (for fast look-ups)
#       ➜ NS_IDS[host]=record_id (needed for deletes)
##############################################################################
echo "🔎 Fetching A-records from NameSilo…"
declare -A NS_IPS NS_IDS

curl -s "$API/dnsListRecords?version=1&type=json&key=$KEY&domain=$DOMAIN" |
  jq -r '.reply.resource_record[]
         | select(.type=="A")
         | [.record_id, .host, .value] | @tsv' |
  while IFS=$'\t' read -r ID HOST IP; do
    NS_IPS["$HOST"]="$IP"
    NS_IDS["$HOST"]="$ID"
  done

##############################################################################
# 3. Delete stale records – present in NameSilo but not in DO (or IP mismatch)
##############################################################################
for HOST in "${!NS_IPS[@]}"; do
  if [[ -z "${DROPLET_IPS[$HOST]+x}" || "${DROPLET_IPS[$HOST]}" != "${NS_IPS[$HOST]}" ]]; then
    echo "🗑️  Deleting stale record  $HOST → ${NS_IPS[$HOST]}"
    curl -s \
      "$API/dnsDeleteRecord?version=1&type=json&key=$KEY&domain=$DOMAIN&rrid=${NS_IDS[$HOST]}" \
      >/dev/null
  fi
done

##############################################################################
# 4. Add missing records – present in DO but not yet in NameSilo
##############################################################################
for HOST in "${!DROPLET_IPS[@]}"; do
  if [[ -z "${NS_IPS[$HOST]+x}" ]]; then
    IP="${DROPLET_IPS[$HOST]}"
    # NameSilo wants the host *relative* to the domain ("" or "@” for apex)
    RRHOST="${HOST%.$DOMAIN}"
    [[ "$RRHOST" == "$HOST" ]] && RRHOST="@"   # apex record
    echo "➕ Adding record         $HOST → $IP"
    curl -s \
      "$API/dnsAddRecord?version=1&type=json&key=$KEY&domain=$DOMAIN&rrtype=A&rrhost=$RRHOST&rrvalue=$IP&rrttl=3600" \
      >/dev/null
  fi
done

echo "✅  NameSilo zone is now fully in sync with live droplets."

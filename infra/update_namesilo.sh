#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Required environment variables (fail fast if any are missing)
###############################################################################
: "${NAMESILO_API_KEY:?Need NAMESILO_API_KEY}"
: "${NAMESILO_DOMAIN:?Need NAMESILO_DOMAIN}"
: "${ROOT_IP:?Need ROOT_IP}"
: "${UI_IP:?Need UI_IP}"
: "${API_IP:?Need API_IP}"
: "${ADMIN_IP:?Need ADMIN_IP}"

###############################################################################
# Desired DNS state
###############################################################################
declare -A DESIRED
DESIRED[""]="$ROOT_IP"          # apex record (e.g. axialy.ai)
DESIRED["ui"]="$UI_IP"          # ui.axialy.ai
DESIRED["api"]="$API_IP"        # api.axialy.ai
DESIRED["admin"]="$ADMIN_IP"    # admin.axialy.ai

API_ROOT="https://www.namesilo.com/api"

###############################################################################
# Fetch current A-records
###############################################################################
xml=$(curl -s "${API_ROOT}/dnsListRecords?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}")

# Extract host|value|record_id for every A record (requires xmlstarlet, present on the GH-Actions image)
mapfile -t records < <(
  xmlstarlet sel -t -m '//resource_record[type="A"]' \
    -v 'host' -o '|' -v 'value' -o '|' -v 'record_id' -n <<<"$xml"
)

###############################################################################
# Work out which records to keep, delete, or create
###############################################################################
declare -A keep
declare -a delete_ids

for rec in "${records[@]}"; do
  IFS='|' read -r host value rid <<<"$rec"
  label=${host%%.${NAMESILO_DOMAIN}}          # strip domain to get sub-label
  [[ "$label" == "$host" ]] && label=""       # apex has no sub-label

  desired=${DESIRED[$label]:-}

  if [[ -n "$desired" ]]; then
    if [[ "$value" == "$desired" && -z "${keep[$label]:-}" ]]; then
      keep[$label]=$rid                       # first correct record ⇒ keep
    else
      delete_ids+=("$rid")                    # duplicates or wrong IPs ⇒ delete
    fi
  fi
done

###############################################################################
# Delete the extras
###############################################################################
for rid in "${delete_ids[@]}"; do
  echo "Deleting rrid=$rid"
  curl -s "${API_ROOT}/dnsDeleteRecord?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrid=${rid}" >/dev/null
done

###############################################################################
# Ensure every desired record exists
###############################################################################
for label in "${!DESIRED[@]}"; do
  if [[ -z "${keep[$label]:-}" ]]; then
    host=$([[ -z "$label" ]] && echo "$NAMESILO_DOMAIN" || echo "${label}.${NAMESILO_DOMAIN}")
    ip=${DESIRED[$label]}
    echo "Adding ${host} → ${ip}"
    curl -s "${API_ROOT}/dnsAddRecord?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrtype=A&rrhost=${host}&rrvalue=${ip}&rrttl=3600" >/dev/null
  fi
done

echo "✅ NameSilo DNS records are now exactly as desired."

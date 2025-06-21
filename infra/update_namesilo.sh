#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# update_namesilo.sh – keep NameSilo DNS in perfect sync with Terraform outputs
# ---------------------------------------------------------------------------
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# ---- list current A-records ------------------------------------------------
list_records () {
  curl -s \
    "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
    jq -r '.namesilo.response.resource_record[] |
           select(.type=="A") |
           { host, ip: .value, id: .record_id }'
}

# ---- helpers ---------------------------------------------------------------
delete_record () { curl -s \
  "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=$1" >/dev/null; }

add_record () {
  local RRHOST="$1" IP="$2"
  local HOST_PARAM; [[ -z "$RRHOST" ]] && HOST_PARAM="" || HOST_PARAM="rrhost=${RRHOST}&"
  curl -s \
    "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# ---- ensure exactly ONE record per host/IP ---------------------------------
upsert () {
  local RRHOST="$1" NEW_IP="$2" SKIP_ADD=0
  local FILTER; [[ -z "$RRHOST" ]] && FILTER='(.host=="'"$DOMAIN"'" or .host=="@")' \
                                   || FILTER='.host=="'"$RRHOST.$DOMAIN"'"'

  list_records | jq -rc "select(${FILTER})" | while read -r rec; do
    local CURR_ID CURR_IP
    CURR_ID=$(jq -r '.id' <<<"$rec")
    CURR_IP=$(jq -r '.ip' <<<"$rec")
    [[ "$CURR_IP" == "$NEW_IP" ]] && SKIP_ADD=1 || delete_record "$CURR_ID"
  done

  [[ $SKIP_ADD -eq 0 ]] && add_record "$RRHOST" "$NEW_IP"
}

# ---- desired state from Terraform -----------------------------------------
IPS_JSON=$(terraform -chdir=infra output -json droplet_ips)
declare -A WANT=(
  [admin]="$(echo "$IPS_JSON" | jq -r '.admin')"
  [ui]="$(   echo "$IPS_JSON" | jq -r '.ui')"
  [api]="$(  echo "$IPS_JSON" | jq -r '.api')"
  [www]="$(  echo "$IPS_JSON" | jq -r '.root')"
  [root]="$( echo "$IPS_JSON" | jq -r '.root')"
)

for h in "${!WANT[@]}"; do
  [[ -z ${WANT[$h]} || ${WANT[$h]} == "null" ]] && { echo "Missing IP for $h"; exit 1; }
done

# ---- reconcile -------------------------------------------------------------
upsert "admin" "${WANT[admin]}"
upsert "ui"    "${WANT[ui]}"
upsert "api"   "${WANT[api]}"
upsert "www"   "${WANT[www]}"
upsert ""      "${WANT[root]}"   # apex

echo "✔  NameSilo DNS now matches Terraform outputs."

#!/usr/bin/env bash
# ------------------------------------------------------------------
# update_namesilo.sh  – keep A-records in sync with droplet IPs
# ------------------------------------------------------------------
set -euo pipefail

KEY="$NAMESILO_API_KEY"
DOMAIN="$NAMESILO_DOMAIN"

# ---------- helper: ensure exactly ONE A-record with desired IP ----
# $1 = rrhost  ("" for apex)   $2 = desired IPv4 address
upsert () {
  local RRHOST="$1"; local IP="$2"

  # Fetch current records only once per call (fast enough)
  local LIST
  LIST=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")

  # jq filter for the host we care about (apex or sub-host)
  local JQ_FILTER
  if [[ -z "$RRHOST" ]]; then      # apex (@)
    JQ_FILTER=".host==\"${DOMAIN}\""
  else
    JQ_FILTER=".host==\"${RRHOST}.${DOMAIN}\""
  fi

  # IDs that ALREADY have the correct IP
  local GOOD_ID
  GOOD_ID=$(echo "$LIST" | jq -r ".namesilo.response.resource_record[]
            | select(.type==\"A\" and (${JQ_FILTER}) and .value==\"${IP}\")
            | .record_id" | head -n 1)

  # IDs that have WRONG IPs  → delete them all
  local BAD_IDS
  BAD_IDS=$(echo "$LIST" | jq -r ".namesilo.response.resource_record[]
            | select(.type==\"A\" and (${JQ_FILTER}) and .value!=\"${IP}\")
            | .record_id")

  for ID in $BAD_IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" > /dev/null
  done

  # If we didn’t find a good record, add or update one
  if [[ -n "$GOOD_ID" ]]; then
    # Already perfect – nothing else to do
    return
  fi

  if [[ -n "$BAD_IDS" ]]; then
    # We deleted the wrong one(s); reuse the first bad ID slot by updating it
    local RRID_FIRST=$(echo "$BAD_IDS" | head -n1)
    local HOST_PARAM=$([[ -z "$RRHOST" ]] && echo "" || echo "rrhost=${RRHOST}&")
    curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${RRID_FIRST}&${HOST_PARAM}rrvalue=${IP}&rrttl=3600" > /dev/null
  else
    # No record at all – create a fresh one
    local HOST_PARAM=$([[ -z "$RRHOST" ]] && echo "" || echo "rrhost=${RRHOST}&")
    curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" > /dev/null
  fi
}

# ---------- fetch droplet IPs from Terraform outputs ---------------
IPS=$(terraform -chdir=infra output -json droplet_ips)
ADMIN_IP=$(echo "$IPS" | jq -r '.admin')
UI_IP=$(echo "$IPS"    | jq -r '.ui')
API_IP=$(echo "$IPS"   | jq -r '.api')
ROOT_IP=$(echo "$IPS"  | jq -r '.root')

# ---------- upsert everything --------------------------------------
upsert "admin" "$ADMIN_IP"
upsert "ui"    "$UI_IP"
upsert "api"   "$API_IP"
upsert "www"   "$ROOT_IP"
upsert ""      "$ROOT_IP"   # apex

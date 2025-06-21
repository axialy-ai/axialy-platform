#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# update_namesilo.sh  – keep NameSilo DNS in perfect sync with Terraform outputs
# ---------------------------------------------------------------------------
set -euo pipefail

# ------------------- config injected by the GitHub-Actions job --------------
KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# ---------------------------------------------------------------------------
# helper: list all current A-records for the domain in one jq-friendly array
# ---------------------------------------------------------------------------
list_records () {
  curl -s \
    "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
    jq -r '.namesilo.response.resource_record[] |
           select(.type=="A") |
           { host, ip: .value, id: .record_id }'
}

# ---------------------------------------------------------------------------
# helper: delete a record by ID (silent/fast)
# ---------------------------------------------------------------------------
delete_record () {
  local ID="$1"
  curl -s \
    "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
    >/dev/null
}

# ---------------------------------------------------------------------------
# helper: add an A-record.  $1 = rrhost ("" for apex),  $2 = IP
# ---------------------------------------------------------------------------
add_record () {
  local RRHOST="$1" IP="$2" HOST_PARAM
  if [[ -z "$RRHOST" ]]; then
    HOST_PARAM=""
  else
    HOST_PARAM="rrhost=${RRHOST}&"
  fi
  curl -s \
    "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# ---------------------------------------------------------------------------
# smarter “upsert”: *ensure exactly one* record with the desired IP
# ---------------------------------------------------------------------------
upsert () {
  local RRHOST="$1" NEW_IP="$2"

  # list current records for this host (apex handled specially)
  local HOST_FILTER
  if [[ -z "$RRHOST" ]]; then
    HOST_FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    HOST_FILTER='.host=="'"$RRHOST.$DOMAIN"'"'
  fi

  # shell → jq → while-read for portability
  list_records | jq -rc "select(${HOST_FILTER})" | while read -r rec; do
    CURR_ID=$(jq -r '.id'  <<<"$rec")
    CURR_IP=$(jq -r '.ip'  <<<"$rec")
    # delete if IP is stale
    if [[ "$CURR_IP" != "$NEW_IP" ]]; then
      delete_record "$CURR_ID"
    else
      # correct IP already present → mark that we’re done
      local SKIP_ADD=1
    fi
  done

  # add the record if it was missing entirely
  [[ ${SKIP_ADD:-0} -eq 0 ]] && add_record "$RRHOST" "$NEW_IP"
}

# ---------------------------------------------------------------------------
# get desired IPs straight from Terraform outputs
# ---------------------------------------------------------------------------
IPS_JSON=$(terraform -chdir=infra output -json droplet_ips)

declare -A WANT=(
  [admin]="$(echo "$IPS_JSON" | jq -r '.admin')"
  [ui]="$(   echo "$IPS_JSON" | jq -r '.ui')"
  [api]="$(  echo "$IPS_JSON" | jq -r '.api')"
  [www]="$(  echo "$IPS_JSON" | jq -r '.root')"   # www → same IP as apex
  [root]="$( echo "$IPS_JSON" | jq -r '.root')"   # apex
)

# sanity guard – bail out if terraform returned nulls
for k in "${!WANT[@]}"; do
  [[ -z "${WANT[$k]}" || "${WANT[$k]}" == "null" ]] && {
    echo "❌  Missing IP for $k (terraform output empty) – aborting." >&2
    exit 1
  }
done

# ---------------------------- run the reconciler ----------------------------
upsert "admin" "${WANT[admin]}"
upsert "ui"    "${WANT[ui]}"
upsert "api"   "${WANT[api]}"
upsert "www"   "${WANT[www]}"
upsert ""      "${WANT[root]}"   # apex / root

echo "✅  NameSilo DNS is now perfectly in sync."

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  update_namesilo.sh  –  Keep A-records at NameSilo in perfect sync
# ---------------------------------------------------------------------------
#  • Deletes *all* stale A-records for the host first
#  • Adds exactly one fresh A-record with the current droplet IP
#  • Works for: apex (@), www, ui, api, admin
# ---------------------------------------------------------------------------

set -euo pipefail

# --- config ---------------------------------------------------------------
KEY=${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}
DOMAIN=${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}

# --- helper: NameSilo API call -------------------------------------------
api() {
  # $1 = operation  ($2 = query-string without leading &)
  curl -s "https://www.namesilo.com/api/$1?version=1&type=json&key=${KEY}&domain=${DOMAIN}&$2"
}

# --- helper: upsert one host ---------------------------------------------
#   $1 = rrhost  ("" for apex)
#   $2 = IPv4 address
upsert() {
  local RR="$1"  IP="$2"

  # 1️⃣  collect ALL existing A-records for this host (any IP)
  local IDS
  IDS=$(api "dnsListRecords" "" | jq -r --arg rr "$RR" --arg dom "$DOMAIN" '
      .namesilo.reply.resource_record[]
      | select(.type=="A" and (
          ($rr==""  and (.host==$dom or .host=="" or .host=="@"))          # apex forms
          or
          ($rr!="" and (.host==$rr       or .host==($rr+"."+$dom)))        # subdomains
        ))
      | .record_id')

  # 2️⃣  delete them
  for id in $IDS; do
    api "dnsDeleteRecord" "rrid=${id}" >/dev/null
  done

  # 3️⃣  add the single, correct record
  local HOST_PARAM
  if [[ -z "$RR" ]]; then
    HOST_PARAM=""              # apex → leave rrhost blank
  else
    HOST_PARAM="rrhost=${RR}&"
  fi
  api "dnsAddRecord" "${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" >/dev/null
}

# --- fetch current droplet IPs from Terraform outputs --------------------
IPS_JSON=$(terraform -chdir=infra output -json droplet_ips)
ROOT_IP=$(  jq -r '.root'  <<<"$IPS_JSON")
ADMIN_IP=$( jq -r '.admin' <<<"$IPS_JSON")
UI_IP=$(    jq -r '.ui'    <<<"$IPS_JSON")
API_IP=$(   jq -r '.api'   <<<"$IPS_JSON")

# --- reconcile all hosts --------------------------------------------------
upsert ""      "$ROOT_IP"     # apex @
upsert "www"   "$ROOT_IP"
upsert "admin" "$ADMIN_IP"
upsert "ui"    "$UI_IP"
upsert "api"   "$API_IP"

echo "✅  DNS A-records for ${DOMAIN} are now clean and up-to-date."

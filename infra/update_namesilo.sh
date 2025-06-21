#!/usr/bin/env bash
set -euo pipefail

# ── Config from GitHub-Actions secrets ───────────────────────────────
KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

#
# upsert HOST  IP
#   • HOST == ""  → apex record (root, “@”)
#   • HOST == "ui" / "api" / "admin" / "www" etc.
#
upsert () {
  local HOST="$1" IP="$2"

  # Apex appears as either "axialy.ai" or "@"
  local FILTER
  if [[ -z "$HOST" ]]; then
    FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    FILTER='.host=="'"$HOST.$DOMAIN"'"'
  fi

  # 1️⃣  List current A-records for that host
  local IDS
  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and '"$FILTER"')
               | .record_id')

  # 2️⃣  Delete every matching record (if any)
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done

  # 3️⃣  Wait until API shows zero remaining records (≤ 5 s)
  for _ in {1..10}; do
    local LEFT
    LEFT=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
            jq -r '[.namesilo.response.resource_record[]
                    | select(.type=="A" and '"$FILTER"')] | length')
    [[ "$LEFT" == 0 ]] && break
    sleep 0.5
  done

  # 4️⃣  Add the single, correct A-record
  local HOST_PARAM
  [[ -n "$HOST" ]] && HOST_PARAM="rrhost=${HOST}&" || HOST_PARAM=""
  curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# ── Pull droplet IPs from Terraform outputs -------------------------
IPS=$(terraform -chdir=infra output -json droplet_ips)

ADMIN_IP=$(echo "$IPS" | jq -r '.admin')
UI_IP=$(echo   "$IPS" | jq -r '.ui')
API_IP=$(echo  "$IPS" | jq -r '.api')
ROOT_IP=$(echo "$IPS" | jq -r '.root')

# ── Enforce “single-record” policy for every host -------------------
upsert "admin" "$ADMIN_IP"
upsert "ui"    "$UI_IP"
upsert "api"   "$API_IP"
upsert "www"   "$ROOT_IP"
upsert ""      "$ROOT_IP"   # apex / @

echo "✅  DNS for ${DOMAIN} now has exactly one A-record per host."

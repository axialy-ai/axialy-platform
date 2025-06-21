#!/usr/bin/env bash
set -euo pipefail

# ── Secrets injected by GitHub Actions ───────────────────────────────
KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

#
# clean_and_add HOST  IP
#
#   HOST == ""   → apex (@)
#   HOST == "www" / "api" / "ui" / "admin"
#
clean_and_add () {
  local HOST="$1" IP="$2"

  # Build a jq expression that matches *all* possible host spellings
  local FILTER
  if [[ -z "$HOST" ]]; then            # apex record
    FILTER='.host=="@" or .host=="'"$DOMAIN"'"'
  else                                  # sub-host (www, api, …)
    FILTER='.host=="'"$HOST"'" or .host=="'"$HOST.$DOMAIN"'"'
  fi

  # 1️⃣  List & collect record-ids we want to delete
  local IDS
  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and ('"$FILTER"'))
               | .record_id')

  # 2️⃣  Delete every matching record
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done

  # 3️⃣  Wait (<=5 s) until the API shows zero remaining matches
  for _ in {1..10}; do
    local LEFT
    LEFT=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
            jq -r '[.namesilo.response.resource_record[]
                    | select(.type=="A" and ('"$FILTER"'))] | length')
    [[ "$LEFT" == 0 ]] && break
    sleep 0.5
  done

  # 4️⃣  Add the single, correct A-record
  local HOST_PARAM
  [[ -n "$HOST" ]] && HOST_PARAM="rrhost=${HOST}&" || HOST_PARAM=""
  curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# ── Fetch fresh droplet IPs from Terraform ------------------------------------
IPS=$(terraform -chdir=infra output -json droplet_ips)

ADMIN_IP=$(echo "$IPS" | jq -r '.admin')
UI_IP=$(echo   "$IPS" | jq -r '.ui')
API_IP=$(echo  "$IPS" | jq -r '.api')
ROOT_IP=$(echo "$IPS" | jq -r '.root')

# ── Enforce “one record per host” --------------------------------------------
clean_and_add "admin" "$ADMIN_IP"
clean_and_add "ui"    "$UI_IP"
clean_and_add "api"   "$API_IP"
clean_and_add "www"   "$ROOT_IP"
clean_and_add ""      "$ROOT_IP"   # apex/@

echo "✅  NameSilo now holds exactly one A-record per host (no stale IPs)."

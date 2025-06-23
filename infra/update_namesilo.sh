# infra/update_namesilo.sh
#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# — Helper: keep *exactly one* A-record for a host
#   $1 = rrhost  ("" for apex)
#   $2 = IPv4 address
upsert () {
  local RRHOST="$1" IP="$2"

  # Apex can appear as "axialy.ai" or "@"
  local JQ_FILTER
  if [[ -z "$RRHOST" ]]; then
    JQ_FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    JQ_FILTER='.host=="'"$RRHOST.$DOMAIN"'"'
  fi

  # 1) List current A-records for that host
  local IDS
  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and '"$JQ_FILTER"')
               | .record_id')

  # 2) Delete them (if any)
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done

  # 3) Wait until they’re really gone (≤ 5 s)
  for _ in {1..10}; do
    local LEFT
    LEFT=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
            jq -r '[.namesilo.response.resource_record[]
                    | select(.type=="A" and '"$JQ_FILTER"')] | length')
    [[ "$LEFT" == 0 ]] && break
    sleep 0.5
  done

  # 4) Add the single, correct record
  local HOST_PARAM
  if [[ -z "$RRHOST" ]]; then
    HOST_PARAM=""
  else
    HOST_PARAM="rrhost=${RRHOST}&"
  fi

  curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# Fetch droplet IPs from Terraform outputs
IPS_JSON=$(terraform -chdir=infra output -json droplet_ips)

ADMIN_IP=$(echo "$IPS_JSON" | jq -r '.admin')
UI_IP=$(echo   "$IPS_JSON" | jq -r '.ui')
API_IP=$(echo  "$IPS_JSON" | jq -r '.api')
ROOT_IP=$(echo "$IPS_JSON" | jq -r '.root')

# Upsert all required records
upsert "admin" "$ADMIN_IP"
upsert "ui"    "$UI_IP"
upsert "api"   "$API_IP"
upsert "www"   "$ROOT_IP"
upsert ""      "$ROOT_IP"   # apex / root record

echo "✔  DNS records for ${DOMAIN} are up-to-date."

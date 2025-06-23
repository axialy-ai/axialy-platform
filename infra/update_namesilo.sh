# infra/update_namesilo.sh
#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# Keep *exactly one* A-record for a host
upsert () {
  local RRHOST="$1" IP="$2"

  # Apex can appear as "axialy.ai" or "@"
  local JQ_FILTER
  if [[ -z "$RRHOST" ]]; then
    JQ_FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    JQ_FILTER='.host=="'"$RRHOST.$DOMAIN"'"'
  fi

  # 1 – list current A-records
  local IDS
  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and '"$JQ_FILTER"')
               | .record_id')

  # 2 – delete them
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done

  # 3 – wait until gone (≤ 5 s)
  for _ in {1..10}; do
    local LEFT
    LEFT=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
            jq -r '[.namesilo.response.resource_record[]
                    | select(.type=="A" and '"$JQ_FILTER"')] | length')
    [[ "$LEFT" == 0 ]] && break
    sleep 0.5
  done

  # 4 – add single correct record
  local HOST_PARAM
  [[ -z "$RRHOST" ]] && HOST_PARAM="" || HOST_PARAM="rrhost=${RRHOST}&"

  curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# Pull droplet IPs
IPS_JSON=$(terraform -chdir=infra output -json droplet_ips)

upsert "admin" "$(echo "$IPS_JSON" | jq -r '.admin')"
upsert "ui"    "$(echo "$IPS_JSON" | jq -r '.ui')"
upsert "api"   "$(echo "$IPS_JSON" | jq -r '.api')"
upsert "www"   "$(echo "$IPS_JSON" | jq -r '.root')"
upsert ""      "$(echo "$IPS_JSON" | jq -r '.root')"   # apex/root

echo "✓  DNS records for ${DOMAIN} are up-to-date."

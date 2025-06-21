#!/usr/bin/env bash
set -Eeuo pipefail

DOMAIN="${NAMESILO_DOMAIN:?missing}"
KEY="${NAMESILO_API_KEY:?missing}"

declare -A HOST2IP=(
  [@]="$ROOT_IP"
  [ui]="$UI_IP"
  [api]="$API_IP"
  [admin]="$ADMIN_IP"
)

records_json="$(curl -fsSL \
  "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")"

# optional one-off debug dump
# echo "$records_json" | jq .

for host in "${!HOST2IP[@]}"; do
  ip="${HOST2IP[$host]}"

  record_id="$(echo "$records_json" |
      jq -r --arg h "$host.${DOMAIN}" '
          .namesilo.reply.resource_record? // []
          | map(select(.host == $h))        | .[0].record_id // empty')"

  if [[ -n "$record_id" ]]; then
    echo "Updating $host -> $ip (rrid=$record_id)"
    curl -fsSL \
      "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${record_id}&rrhost=${host}&rrvalue=${ip}&rrttl=3600" \
      >/dev/null
  else
    echo "Adding $host -> $ip"
    curl -fsSL \
      "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrtype=A&rrhost=${host}&rrvalue=${ip}&rrttl=3600" \
      >/dev/null
  fi
done

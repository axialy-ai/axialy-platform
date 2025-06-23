#!/usr/bin/env bash
set -euo pipefail

# Required: doctl installed & authenticated
# Required: NAMESILO_API_KEY and DOMAIN set as env vars

declare -A DROPLETS=(
  ["ui"]="ui"
  ["api"]="api"
  ["admin"]="admin"
  ["root"]=""
)

for name in "${!DROPLETS[@]}"; do
  RRHOST="${DROPLETS[$name]}"
  HOST_PARAM=$([ -z "$RRHOST" ] && echo "$DOMAIN" || echo "$RRHOST.$DOMAIN")

  # Check if droplet exists
  EXISTS=$(doctl compute droplet list --format Name --no-header | grep -w "$HOST_PARAM" || true)

  if [ -z "$EXISTS" ]; then
    echo "🧹 Droplet '$HOST_PARAM' missing. Removing any matching A records..."
    RECORDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")
    IDS=$(echo "$RECORDS" | jq -r ".namesilo.response.resource_record[] |
          select(.type==\"A\" and ((.host==\"${DOMAIN}\" and \"$RRHOST\"==\"\") or .host==\"${RRHOST}.${DOMAIN}\")) |
          .record_id")
    for ID in $IDS; do
      echo "❌ Deleting DNS record ID $ID for $HOST_PARAM"
      curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" > /dev/null
    done
  else
    echo "✅ Droplet '$HOST_PARAM' exists — no DNS records deleted."
  fi
done

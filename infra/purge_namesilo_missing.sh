#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

delete_a_records () {
  local RRHOST="$1"
  local JQ_FILTER
  if [[ -z "$RRHOST" ]]; then
    JQ_FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    JQ_FILTER='.host=="'"$RRHOST.$DOMAIN"'"'
  fi

  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and '"$JQ_FILTER"')
               | .record_id')
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done
}

declare -A HOSTS=( ["admin"]="admin" ["ui"]="ui" ["api"]="api" ["root"]="" ["www"]="www" )

for RES in "${!HOSTS[@]}"; do
  HOST="${HOSTS[$RES]}"
  NAME=$([[ "$RES" == "root" ]] && echo "axialy.ai" || echo "${RES}.axialy.ai")

  if ! doctl compute droplet list --format Name --no-header | grep -qw "$NAME"; then
    delete_a_records "$HOST"
  fi
done

# infra/purge_namesilo_missing.sh   ← ADD this new file
#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# Helper – delete *all* A-records for a given rrhost ("": apex)
delete_a_records () {
  local RRHOST="$1"

  # Apex can appear as "axialy.ai" or "@"
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

# Map of droplet resource → rrhost value ("" = apex)
declare -A HOSTS=(
  ["admin"]="admin"
  ["ui"]="ui"
  ["api"]="api"
  ["root"]=""      # apex record
  ["www"]="www"    # convenience www
)

echo "🔍  Checking which droplets are missing…"

for RES in "${!HOSTS[@]}"; do
  HOST="${HOSTS[$RES]}"

  # droplet DNS name in DO
  NAME=$(
    case "$RES" in
      root)  echo "axialy.ai" ;;
      *)     echo "${RES}.axialy.ai" ;;
    esac
  )

  if ! doctl compute droplet list --format Name --no-header | grep -qw "$NAME"; then
    echo "🧹  Droplet '${NAME}' NOT found – purging its A-records in NameSilo"
    delete_a_records "$HOST"
  fi
done

echo "✓  Purge complete – stale A-records removed where droplets are absent."

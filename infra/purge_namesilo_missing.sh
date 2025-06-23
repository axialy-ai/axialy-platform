#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# --- helpers ---------------------------------------------------------------
json_records() {
  # echo the whole record list as a normalised JSON array
  curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
    jq -c '.namesilo.response.resource_record
           | if type=="array" then .        # already an array
             elif type=="object" then [.]   # single object -> wrap
             else []                        # null -> empty array
             end'
}

delete_a_records() {
  local rrhost="$1" jq_filter ids recs
  if [[ -z "$rrhost" ]]; then
    jq_filter='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    jq_filter='.host=="'"$rrhost.$DOMAIN"'"'
  fi

  recs=$(json_records)
  ids=$(jq -r '[.][] | select(.type=="A" and '"$jq_filter"') | .record_id' <<<"$recs")

  for id in $ids; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${id}" >/dev/null
  done
}

# Map of droplet resource → RR host
declare -A HOSTS=( ["admin"]="admin" ["ui"]="ui" ["api"]="api" ["root"]="" ["www"]="www" )

for res in "${!HOSTS[@]}"; do
  host="${HOSTS[$res]}"
  name=$([[ "$res" == "root" ]] && echo "axialy.ai" || echo "${res}.axialy.ai")

  if ! doctl compute droplet list --format Name --no-header | grep -qw "$name"; then
    delete_a_records "$host"
  fi
done

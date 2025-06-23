#!/usr/bin/env bash
# Deletes all A-records for any droplet *that does not yet exist* so
# NameSilo is clean before Terraform creates the replacement droplet.

set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

declare -A HOSTS=(                # droplet-name → rrhost
  ["admin.axialy.ai"]="admin"
  ["ui.axialy.ai"]="ui"
  ["api.axialy.ai"]="api"
  ["axialy.ai"]=""                # apex
  ["www.axialy.ai"]="www"
)

droplet_exists() {                # $1 = FQDN
  doctl compute droplet list --format Name --no-header | grep -qx "$1"
}

delete_records() {                # $1 = rrhost  ("" = apex)
  local RRHOST="$1"
  local FILTER
  if [[ -z "$RRHOST" ]]; then
    FILTER='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    FILTER='.host=="'"$RRHOST.$DOMAIN"'"'
  fi
  local IDS
  IDS=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
        jq -r '.namesilo.response.resource_record[]
               | select(.type=="A" and '"$FILTER"')
               | .record_id')
  for ID in $IDS; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done
  [[ -n "$IDS" ]] && echo "🧹  Deleted stale A-records for '${RRHOST:-@}'."
}

for FQDN in "${!HOSTS[@]}"; do
  if ! droplet_exists "$FQDN"; then
    delete_records "${HOSTS[$FQDN]}"
  fi
done

echo "✅  NameSilo pre-cleanup complete."

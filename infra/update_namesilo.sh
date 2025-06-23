#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# required env-vars
###############################################################################
: "${NAMESILO_API_KEY:?}"
: "${NAMESILO_DOMAIN:?}"
: "${ROOT_IP:?}"
: "${UI_IP:?}"
: "${API_IP:?}"
: "${ADMIN_IP:?}"

###############################################################################
# desired state – use “@” for zone-apex to avoid empty-key bug
###############################################################################
declare -A WANT=(
  ["@"]="$ROOT_IP"      # axialy.ai
  ["ui"]="$UI_IP"       # ui.axialy.ai
  ["api"]="$API_IP"     # api.axialy.ai
  ["admin"]="$ADMIN_IP" # admin.axialy.ai
)

API_ROOT="https://www.namesilo.com/api"

###############################################################################
# current A records
###############################################################################
xml="$(curl -s "${API_ROOT}/dnsListRecords?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}")"

mapfile -t recs < <(
  xmlstarlet sel -t -m '//resource_record[type="A"]' \
    -v 'host' -o '|' -v 'value' -o '|' -v 'record_id' -n <<<"$xml"
)

###############################################################################
# decide keep / delete
###############################################################################
declare -A keep
delete_ids=()

for r in "${recs[@]}"; do
  IFS='|' read -r host val rid <<<"$r"

  if [[ "$host" == "$NAMESILO_DOMAIN" ]]; then
    label="@"
  else
    label="${host/%.${NAMESILO_DOMAIN}}"
  fi

  want="${WANT[$label]:-}"

  if [[ -n "$want" ]]; then
    if [[ "$val" == "$want" && -z "${keep[$label]:-}" ]]; then
      keep[$label]="$rid"            # first correct one → keep
    else
      delete_ids+=("$rid")           # duplicates / wrong IPs
    fi
  fi
done

###############################################################################
# delete extras
###############################################################################
for rid in "${delete_ids[@]}"; do
  curl -s "${API_ROOT}/dnsDeleteRecord?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrid=${rid}" >/dev/null
done

###############################################################################
# add any missing
###############################################################################
for label in "${!WANT[@]}"; do
  [[ -n "${keep[$label]:-}" ]] && continue

  rrhost=$([[ "$label" == "@" ]] && echo "$NAMESILO_DOMAIN" || echo "${label}.${NAMESILO_DOMAIN}")
  ip="${WANT[$label]}"

  curl -s "${API_ROOT}/dnsAddRecord?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrtype=A&rrhost=${rrhost}&rrvalue=${ip}&rrttl=3600" >/dev/null
done

#!/usr/bin/env bash
set -euo pipefail

#--------------------------------------------------------------------
# Required environment (fail fast if anything is missing)
#--------------------------------------------------------------------
: "${NAMESILO_API_KEY:?missing NAMESILO_API_KEY}"
: "${NAMESILO_DOMAIN:?missing NAMESILO_DOMAIN}"
: "${ROOT_IP:?missing ROOT_IP}"
: "${UI_IP:?missing UI_IP}"
: "${API_IP:?missing API_IP}"
: "${ADMIN_IP:?missing ADMIN_IP}"

API="https://www.namesilo.com/api"

#--------------------------------------------------------------------
# Desired state  (labels → IP)
#   • '@' is the zone–apex (axialy.ai)
#--------------------------------------------------------------------
declare -A WANT=(
  ["@"]="$ROOT_IP"
  ["ui"]="$UI_IP"
  ["api"]="$API_IP"
  ["admin"]="$ADMIN_IP"
)

#--------------------------------------------------------------------
# Fetch current A records
#--------------------------------------------------------------------
xml="$(curl -s "${API}/dnsListRecords?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}")"

mapfile -t RECS < <(
  xmlstarlet sel -t -m '//resource_record[type="A"]' \
    -v 'host' -o '|' -v 'value' -o '|' -v 'record_id' -n \
    <<<"${xml}"
)

#--------------------------------------------------------------------
# Work out what to KEEP vs DELETE
#--------------------------------------------------------------------
declare -A kept       # label -> record-id that we’ll keep
delete_ids=()

for rec in "${RECS[@]}"; do
  IFS='|' read -r host ip rid <<<"$rec"

  # derive label from the host returned by API
  case "$host" in
    "$NAMESILO_DOMAIN") label="@" ;;            # root
    *)  label="${host/%.${NAMESILO_DOMAIN}}" ;;  # strip ".axialy.ai"
  esac

  want_ip="${WANT[$label]:-}"

  if [[ -n "$want_ip" ]]; then
    # if matches desired IP and we haven’t kept one for this label, keep it
    if [[ "$ip" == "$want_ip" && -z "${kept[$label]:-}" ]]; then
      kept[$label]="$rid"
    else
      delete_ids+=("$rid")   # duplicates or wrong IP
    fi
  else
    delete_ids+=("$rid")     # not in desired set at all
  fi
done

#--------------------------------------------------------------------
# Purge the junk
#--------------------------------------------------------------------
for rid in "${delete_ids[@]}"; do
  curl -s \
    "${API}/dnsDeleteRecord?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrid=${rid}" \
    >/dev/null
done

#--------------------------------------------------------------------
# Add anything missing
#--------------------------------------------------------------------
for label in "${!WANT[@]}"; do
  [[ -n "${kept[$label]:-}" ]] && continue   # already have a good one

  rrhost=$([[ "$label" == "@" ]] && echo "@" || echo "$label")
  curl -s \
    "${API}/dnsAddRecord?version=1&type=xml&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrtype=A&rrhost=${rrhost}&rrvalue=${WANT[$label]}&rrttl=3600" \
    >/dev/null
done

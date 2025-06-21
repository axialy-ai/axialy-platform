#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?}"
DOMAIN="${NAMESILO_DOMAIN:?}"

# Desired final state – label → IP
IPS=$(terraform -chdir=infra output -json droplet_ips)
declare -A WANT=(
  [""]=   "$(jq -r '.root'  <<<"$IPS")"   # apex '@'
  ["www"]="$(jq -r '.root'  <<<"$IPS")"
  ["api"]="$(jq -r '.api'   <<<"$IPS")"
  ["ui"]="$(jq  -r '.ui'    <<<"$IPS")"
  ["admin"]="$(jq -r '.admin'<<<"$IPS")"
)

ns_api() { curl -sS "$@"; }

# ------------------------------------------------------------------
echo "▶ Listing current records …"
JSON=$(ns_api "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")

# Build list: id host ip
mapfile -t REC < <(
  echo "$JSON" |
  jq -r '.namesilo.response.resource_record[]
         | select(.type=="A")
         | [.record_id, .host, .value] | @tsv')

# ------------------------------------------------------------------
echo "▶ Purging stale A-records …"
for LINE in "${REC[@]}"; do
  IFS=$'\t' read -r ID HOST VALUE <<<"$LINE"

  # Convert full host → label used in WANT ("", www, api …)
  if [[ "$HOST" == "$DOMAIN" ]];       then LABEL="";
  elif [[ "$HOST" == *".${DOMAIN}" ]]; then LABEL="${HOST%%.${DOMAIN}}";
  else                                       continue; fi # not ours

  if [[ -n "${WANT[$LABEL]+x}" && "${WANT[$LABEL]}" == "$VALUE" ]]; then
    # correct record → keep
    unset "WANT[$LABEL]"              # mark as already present
  else
    # stale or duplicate → delete
    echo "  • deleting [$HOST] $VALUE"
    ns_api "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  fi
done

# ------------------------------------------------------------------
echo "▶ Adding missing A-records …"
for LABEL in "${!WANT[@]}"; do
  IP="${WANT[$LABEL]}"
  HOSTARG=""
  [[ -n "$LABEL" ]] && HOSTARG="rrhost=${LABEL}&"
  echo "  • adding [${LABEL:-@}] $IP"
  ns_api "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOSTARG}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
done

echo "✅ DNS is now exactly one A-record per managed host."

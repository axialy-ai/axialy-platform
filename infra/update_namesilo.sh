# ---------- helper: leave EXACTLY ONE A-record -----------------------
# $1 = rrhost ("" for apex)   $2 = IPv4 address
upsert () {
  local RRHOST="$1"; local IP="$2"

  local LIST
  LIST=$(curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")

  # build jq filter for the host
  local JQ_FILTER
  if [[ -z "$RRHOST" ]]; then
    JQ_FILTER=".host==\"${DOMAIN}\""
  else
    JQ_FILTER=".host==\"${RRHOST}.${DOMAIN}\""
  fi

  # 1️⃣  delete *all* existing A-records for that host
  echo "$LIST" | jq -r ".namesilo.response.resource_record[]
          | select(.type==\"A\" and (${JQ_FILTER}))
          | .record_id" \
        | xargs -I{} -r curl -s \
            "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid={}" \
            >/dev/null

  # 2️⃣  add the single correct record
  local HOST_PARAM=$([[ -z "$RRHOST" ]] && echo "" || echo "rrhost=${RRHOST}&")
  curl -s \
    "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_PARAM}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

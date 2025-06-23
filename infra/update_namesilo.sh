#!/usr/bin/env bash
#
# update_namesilo.sh  –  keep NameSilo A-records in sync with Terraform outputs
#
# EXPECTED ENVIRONMENT --------------------------------------------------------
#   NAMESILO_API_KEY   – NameSilo API key (set in the GH workflow secrets)
#   NAMESILO_DOMAIN    – e.g.  axialy.ai
#
# The workflow step that calls this script already exports:
#   ROOT_IP  UI_IP  API_IP  ADMIN_IP  (and the repo root is the CWD)
#
# If something goes wrong the script exits non-zero so the job turns red.
# -----------------------------------------------------------------------------

set -euo pipefail

###############################################################################
# 1. Build the desired-state map from the env vars we were handed
###############################################################################
declare -A DESIRED=(
  ["@"]="$ROOT_IP"
  ["www"]="$ROOT_IP"   # convenience alias
  ["ui"]="$UI_IP"
  ["api"]="$API_IP"
  ["admin"]="$ADMIN_IP"
)

###############################################################################
# 2. Download **current** DNS records from NameSilo
###############################################################################
KEY="${NAMESILO_API_KEY:?NAMESILO_API_KEY not set}"
DOMAIN="${NAMESILO_DOMAIN:?NAMESILO_DOMAIN not set}"
BASE="https://www.namesilo.com/api"

DNS_JSON=$(curl -s \
  "${BASE}/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")

# Make absolutely sure the request succeeded
if [[ $(echo "$DNS_JSON" | jq -r '.namesilo.reply.code') != "300" ]]; then
  echo "❌  dnsListRecords failed:" >&2
  echo "$DNS_JSON" | jq -C . >&2
  exit 1
fi

# Pull out only A-records:  record_id|subdomain|value
mapfile -t CURRENT < <(
  echo "$DNS_JSON" |
    jq -r '
      .namesilo.reply.resource_record[]?
      | select(.type=="A")
      | "\(.record_id)|\(.host)|\(.value)"'
)

###############################################################################
# 3. Iterate through CURRENT and reconcile against DESIRED
###############################################################################
for rec in "${CURRENT[@]}"; do
  IFS='|' read -r RRID HOST VALUE <<<"$rec"

  # translate FQDN → simple label used in DESIRED map
  SUB=${HOST%."$DOMAIN"}          # strip “.example.com”
  SUB=${SUB%.}                    # strip trailing dot
  [[ -z "$SUB" || "$SUB" == "$DOMAIN" ]] && SUB="@"

  WANT=${DESIRED[$SUB]-}          # may be empty (unset)

  if [[ -z "$WANT" ]]; then
    # this record is NOT wanted → delete it
    curl -s \
      "${BASE}/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${RRID}" \
      >/dev/null
    echo "🗑  removed obsolete  ${HOST}  (${VALUE})"
  elif [[ "$WANT" != "$VALUE" ]]; then
    # exists but wrong IP → update it
    RRHOST=$([[ "$SUB" == "@" ]] && echo "@" || echo "$SUB")
    curl -s \
      "${BASE}/dnsUpdateRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${RRID}&rrhost=${RRHOST}&rrvalue=${WANT}&rrttl=3600" \
      >/dev/null
    echo "🔄  updated ${RRHOST}.${DOMAIN}  ${VALUE} → ${WANT}"
    DESIRED[$SUB]=""               # mark satisfied
  else
    # already perfect → mark satisfied
    DESIRED[$SUB]=""
  fi
done

###############################################################################
# 4. Any remaining items in DESIRED were missing → add them
###############################################################################
for SUB in "${!DESIRED[@]}"; do
  IP=${DESIRED[$SUB]}
  [[ -z "$IP" ]] && continue      # already handled above

  RRHOST=$([[ "$SUB" == "@" ]] && echo "@" || echo "$SUB")
  curl -s \
    "${BASE}/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrtype=A&rrhost=${RRHOST}&rrvalue=${IP}&rrttl=3600" \
    >/dev/null
  echo "➕  added   ${RRHOST}.${DOMAIN}  →  ${IP}"
done

###############################################################################
# 5. (optional) clean up stray DNSSEC DS records pointing at dead servers -----
# Uncomment if you ever rotate DS keys automatically
# DS_JSON=$(curl -s "${BASE}/dnsSecListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}")
# for row in $(echo "$DS_JSON" | jq -r '.namesilo.reply.ds_record[]? | @base64'); do
#   _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
#   DIGEST=$(_jq '.digest')
#   KEYTAG=$(_jq '.key_tag')
#   DIGTYPE=$(_jq '.digest_type')
#   ALG=$(_jq '.algorithm')
#   # your own logic to decide when a DS record is “stale” goes here
#   # curl -s "${BASE}/dnsSecDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&digest=${DIGEST}&keyTag=${KEYTAG}&digestType=${DIGTYPE}&alg=${ALG}" >/dev/null
# done
###############################################################################

echo "✅  DNS for ${DOMAIN} is now fully reconciled."

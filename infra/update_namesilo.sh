#!/usr/bin/env bash
#
# update_namesilo.sh  —  “one record per host” enforcement
#
#  ▸ deletes *all* existing A-records that belong to a host
#  ▸ adds one fresh A-record with the live IP
#
#  Host parameter:
#     ""      → apex (@)
#     "www"   → www.axialy.ai
#     "api"   → api.axialy.ai     …etc.
#
set -euo pipefail

# ── Secrets from GitHub Actions ──────────────────────────────────────
KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# --------------------------------------------------------------------
ns_api() { curl -sS "$@"; }              # wrapper for quiet curl

purge_and_add() {                       # purge_and_add HOST IP
  local HOST="$1" IP="$2"

  # ---- Build match expression that covers both host variants -------
  local JQ_MATCH
  if [[ -z "$HOST" ]]; then             # apex
    JQ_MATCH='.host=="@" or .host=="'"$DOMAIN"'"'
  else                                  # sub-host
    JQ_MATCH='.host=="'"$HOST"'" or .host=="'"$HOST.$DOMAIN"'"'
  fi

  # ---- Collect *ALL* A-record IDs for this host --------------------
  mapfile -t IDS < <(
    ns_api "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
    jq -r '.namesilo.response.resource_record[]
           | select(.type=="A" and ('"$JQ_MATCH"')) | .record_id'
  )

  # ---- Delete them one by one --------------------------------------
  for ID in "${IDS[@]}"; do
    ns_api "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
  done

  # ---- Add the lone, correct record --------------------------------
  local HOST_ARG=""
  [[ -n "$HOST" ]] && HOST_ARG="rrhost=${HOST}&"
  ns_api "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${HOST_ARG}rrvalue=${IP}&rrtype=A&rrttl=3600" \
    >/dev/null
}

# ── Current droplet IPs from Terraform output -----------------------
IPS=$(terraform -chdir=infra output -json droplet_ips)
ADMIN_IP=$(jq -r '.admin' <<<"$IPS")
UI_IP=$(jq    -r '.ui'    <<<"$IPS")
API_IP=$(jq   -r '.api'   <<<"$IPS")
ROOT_IP=$(jq  -r '.root'  <<<"$IPS")

# ── Enforce “exactly one record per host” ---------------------------
purge_and_add "admin" "$ADMIN_IP"
purge_and_add "ui"    "$UI_IP"
purge_and_add "api"   "$API_IP"
purge_and_add "www"   "$ROOT_IP"
purge_and_add ""      "$ROOT_IP"   # apex (@)

echo "✅  NameSilo A-records are now clean: one per host, no stale IPs."

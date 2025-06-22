#!/usr/bin/env bash
#
# Synchronise A-records at NameSilo with the droplet IPs that Terraform
# just produced.  All logic lives in this one script – the workflow only
# needs to execute it.
#
# Expected environment variables (workflow step sets these automatically):
#   NAMESILO_API_KEY   – your NameSilo API key
#   NAMESILO_DOMAIN    – e.g.  axialy.ai
#
# Needs `jq` in the runner image (present on GitHub-Hosted Ubuntu images).

set -euo pipefail

##############################################################################
# 0.  Work in the directory that holds the Terraform state -- hot-swap safe  #
##############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"                   # → repo/infra

##############################################################################
# 1.  Gather desired state from Terraform output                             #
##############################################################################
IPS_JSON=$(terraform output -json droplet_ips)

ROOT_IP=$(  echo "$IPS_JSON" | jq -r '.root'  )
UI_IP=$(    echo "$IPS_JSON" | jq -r '.ui'    )
API_IP=$(   echo "$IPS_JSON" | jq -r '.api'   )
ADMIN_IP=$( echo "$IPS_JSON" | jq -r '.admin' )

declare -A DESIRED=(
  ["@"]="$ROOT_IP"    # apex
  ["www"]="$ROOT_IP"  # convenience CNAME-ish A-record
  ["ui"]="$UI_IP"
  ["api"]="$API_IP"
  ["admin"]="$ADMIN_IP"
)

##############################################################################
# 2.  Current state from NameSilo                                            #
##############################################################################
NS_KEY=${NAMESILO_API_KEY:?NAMESILO_API_KEY not set}
DOMAIN=${NAMESILO_DOMAIN:?NAMESILO_DOMAIN not set}
NS_BASE="https://www.namesilo.com/api"

DNS_JSON=$(curl -s \
  "${NS_BASE}/dnsListRecords?version=1&type=json&key=${NS_KEY}&domain=${DOMAIN}")

# Extract existing A-records as  id|host|value  tuples
mapfile -t CURRENT < <(
  echo "$DNS_JSON" |
    jq -r '.namesilo.response.resource_record[]
           | select(.type=="A")
           | "\(.record_id)|\(.host)|\(.value)"'
)

##############################################################################
# 3.  Reconcile – delete / update anything out of spec                       #
##############################################################################
for rec in "${CURRENT[@]}"; do
  IFS='|' read -r ID HOST VALUE <<<"$rec"

  # Convert “axialy.ai” → “@”, “ui.axialy.ai.” → “ui”, etc.
  SUB=${HOST%.$DOMAIN}
  SUB=${SUB%.}                       # strip trailing dot
  [[ "$SUB" == "$DOMAIN" || -z "$SUB" ]] && SUB="@"

  WANT_IP=${DESIRED[$SUB]-}

  if [[ -z "$WANT_IP" ]]; then               # no longer wanted → delete
    curl -s "${NS_BASE}/dnsDeleteRecord?version=1&type=json&key=${NS_KEY}&domain=${DOMAIN}&rrid=${ID}" \
      >/dev/null
    echo "🗑  removed obsolete  ${HOST} (${VALUE})"
  elif [[ "$WANT_IP" != "$VALUE" ]]; then    # wrong IP → update
    curl -s "${NS_BASE}/dnsUpdateRecord?version=1&type=json&key=${NS_KEY}&domain=${DOMAIN}&rrid=${ID}&rrhost=${SUB}&rrvalue=${WANT_IP}&rrttl=3600" \
      >/dev/null
    echo "🔄  updated ${SUB}.${DOMAIN}  ${VALUE} → ${WANT_IP}"
    DESIRED[$SUB]=""                         # mark as satisfied
  else                                       # correct – keep, mark satisfied
    DESIRED[$SUB]=""
  fi
done

##############################################################################
# 4.  Add any records that were missing                                      #
##############################################################################
for SUB in "${!DESIRED[@]}"; do
  IP=${DESIRED[$SUB]}
  [[ -z "$IP" ]] && continue                # already handled above

  RRHOST=$SUB
  [[ "$SUB" == "@" ]] && RRHOST="@"         # apex placeholder

  curl -s "${NS_BASE}/dnsAddRecord?version=1&type=json&key=${NS_KEY}&domain=${DOMAIN}&rrtype=A&rrhost=${RRHOST}&rrvalue=${IP}&rrttl=3600" \
    >/dev/null
  echo "➕  added   ${RRHOST}.${DOMAIN}  →  ${IP}"
done

echo "✅  DNS records for ${DOMAIN} are now up-to-date."

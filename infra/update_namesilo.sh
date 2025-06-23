#!/usr/bin/env bash
# infra/update_namesilo.sh
# ---------------------------------------------------------------------------
# Creates / updates exactly one A-record for each droplet that Terraform
# manages.  Safe-no-op if the record already points at the correct IP.
#
# ENV expected (exported earlier in the workflow)
#   NAMESILO_API_KEY   ▸ Your API key     (already set in workflow env)
#   NAMESILO_DOMAIN    ▸ axialy.ai        (already set in workflow env)
#   ROOT_IP  UI_IP  API_IP  ADMIN_IP      ▸ from terraform output
# ---------------------------------------------------------------------------

set -euo pipefail

# 1) ----------------------------------------------------------------------------
# mapping “terraform resource name” ➜ fqdn ➜ corresponding IP variable
declare -A HOST_MAP=(
  [root]="axialy.ai"
  [ui]="ui.axialy.ai"
  [api]="api.axialy.ai"
  [admin]="admin.axialy.ai"
)

declare -A IP_VAR_MAP=(
  [root]="ROOT_IP"
  [ui]="UI_IP"
  [api]="API_IP"
  [admin]="ADMIN_IP"
)

# 2) ----------------------------------------------------------------------------
# Fetch *all* existing A-records once (JSON)
ALL=$(curl -s \
  "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}")

# 3) ----------------------------------------------------------------------------
update_or_add() {
  local fqdn=$1
  local want_ip=$2

  # Does a correct A-record already exist?
  correct=$(echo "$ALL" | jq -r \
        --arg F "$fqdn" --arg IP "$want_ip" '
        .reply.resource_record[]
        | select(.type=="A" and .host==$F and .value==$IP)
        | .record_id')
  if [[ -n "$correct" ]]; then
    echo "✓  ${fqdn} already points to ${want_ip}"
    return
  fi

  # Gather *all* A-records for this FQDN (could be 0, 1, or many/wrong)
  mapfile -t rec_ids < <(echo "$ALL" | jq -r \
        --arg F "$fqdn" '.reply.resource_record[]
        | select(.type=="A" and .host==$F)
        | .record_id')

  if ((${#rec_ids[@]})); then
    # Update the first record, delete any extras
    primary=${rec_ids[0]}
    echo -n "↻  Updating ${fqdn} (${primary}) → ${want_ip} … "
    code=$(curl -s \
      "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=json&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrid=${primary}&rrhost=${fqdn}&rrvalue=${want_ip}&rrttl=3600" \
      | jq -r '.reply.code')
    [[ "$code" == "300" ]] && echo "done" || { echo "FAILED (code $code)"; exit 1; }

    # Remove duplicates, if any
    for ((i=1;i<${#rec_ids[@]};i++)); do
      rid=${rec_ids[i]}
      echo -n "   deleting duplicate ${rid} … "
      curl -s \
        "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrid=${rid}" \
        | jq -e '.reply.code=="300"' >/dev/null && echo ok || { echo FAIL; exit 1; }
    done
  else
    # No record → add one
    echo -n "+  Adding ${fqdn} → ${want_ip} … "
    code=$(curl -s \
      "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${NAMESILO_API_KEY}&domain=${NAMESILO_DOMAIN}&rrtype=A&rrhost=${fqdn}&rrvalue=${want_ip}&rrttl=3600" \
      | jq -r '.reply.code')
    [[ "$code" == "300" ]] && echo "done" || { echo "FAILED (code $code)"; exit 1; }
  fi
}

# 4) ----------------------------------------------------------------------------
echo "── Synchronising NameSilo A-records ──────────────────────────────────────"
for res in "${!HOST_MAP[@]}"; do
  fqdn=${HOST_MAP[$res]}
  ip_var=${IP_VAR_MAP[$res]}
  want_ip=${!ip_var:-""}

  # If Terraform didn't output an IP for this droplet (because it wasn't created),
  # skip it entirely.
  [[ -z "$want_ip" || "$want_ip" == "null" ]] && continue

  update_or_add "$fqdn" "$want_ip"
done
echo "──────────────────────────────────────────────────────────────────────────"

#!/usr/bin/env bash
# infra/update_namesilo.sh
# ---------------------------------------------------------------------------
# Sync NameSilo A-records with the 4 droplets Terraform manages.
#   • no “nuke-all”: only touch hosts Terraform just created/updated
#   • zero duplicates left behind
#   • exits non-zero on ANY NameSilo error so the workflow fails visibly
#
# ENV already set by the workflow ----------------------------
#   NAMESILO_API_KEY        Your key
#   NAMESILO_DOMAIN         axialy.ai
#   ROOT_IP  UI_IP  API_IP  ADMIN_IP   (exported from terraform output)
# ---------------------------------------------------------------------------

set -euo pipefail

DOMAIN="${NAMESILO_DOMAIN}"
API_KEY="${NAMESILO_API_KEY}"

# ── 1. Which host ↔︎ droplet IP? ────────────────────────────────────────────
declare -A HOSTPARTS=(
  [root]="@"      # apex record – NameSilo wants '@'
  [ui]="ui"
  [api]="api"
  [admin]="admin"
)

declare -A IPVARS=(
  [root]="ROOT_IP"
  [ui]="UI_IP"
  [api]="API_IP"
  [admin]="ADMIN_IP"
)

# ── 2. Pull ALL existing A-records once (JSON) ──────────────────────────────
ALL_REC=$(curl -s \
  "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}")

# helper → true if NameSilo reply was success (code 300)
ok() { jq -e '.reply.code=="300"' >/dev/null; }

# ── 3. Core routine: ensure single correct record per host ──────────────────
sync_host() {
  local host_part="$1" want_ip="$2"

  # The host value as NameSilo stores it (it *expands* '@' to the FQDN)
  # Accept any of these as “belongs to this host”
  host_regex=''
  if [[ "$host_part" == "@" ]]; then
    host_regex="^${DOMAIN}(\\.${DOMAIN})*\$"        # apex & doubled variants
  else
    host_regex="^${host_part}(\\.${DOMAIN})+\$"     # ui.axialy.ai plus any doubled
  fi

  # collect record IDs for *this* host
  mapfile -t rec_ids < <(echo "$ALL_REC" | jq -r \
      --arg re "$host_regex" \
      '.reply.resource_record[]
       | select(.type=="A" and (.host|test($re)))
       | .record_id')

  # is one of them already correct?
  correct_id=''
  for rid in "${rec_ids[@]:-}"; do
    val=$(echo "$ALL_REC" | jq -r \
          --arg rid "$rid" \
          '.reply.resource_record[] | select(.record_id==$rid) | .value')
    if [[ "$val" == "$want_ip" ]]; then
      correct_id="$rid"
      break
    fi
  done

  # -------------------------------------------------------------------------
  if [[ -n "$correct_id" ]]; then
    # keep EXACTLY this record → delete any extra duplicates
    for rid in "${rec_ids[@]}"; do
      [[ "$rid" == "$correct_id" ]] && continue
      echo "🗑️  $host_part : deleting duplicate rrid=$rid"
      curl -s \
        "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}&rrid=${rid}" \
        | ok || { echo "NameSilo error while deleting $rid"; exit 1; }
    done
    echo "✓  $host_part already correct (${want_ip})"
    return
  fi

  # -------------------------------------------------------------------------
  if ((${#rec_ids[@]})); then
    # update the first wrong record, then delete the rest
    primary=${rec_ids[0]}
    echo "↻  $host_part : updating rrid=$primary → ${want_ip}"
    curl -s \
      "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}&rrid=${primary}&rrhost=${host_part}&rrvalue=${want_ip}&rrttl=3600" \
      | ok || { echo "NameSilo update failed ($primary)"; exit 1; }

    for rid in "${rec_ids[@]:1}"; do
      echo "🗑️  $host_part : removing stale dup rrid=$rid"
      curl -s \
        "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}&rrid=${rid}" \
        | ok || { echo "NameSilo error deleting $rid"; exit 1; }
    done
  else
    # no record at all → add one
    echo "+  $host_part : adding ${want_ip}"
    curl -s \
      "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}&rrtype=A&rrhost=${host_part}&rrvalue=${want_ip}&rrttl=3600" \
      | ok || { echo "NameSilo add failed ($host_part)"; exit 1; }
  fi
}

# ── 4. Iterate through the four droplets ────────────────────────────────────
echo "── Syncing NameSilo DNS for ${DOMAIN} ───────────────────────────"
for res in "${!HOSTPARTS[@]}"; do
  ip_var=${IPVARS[$res]}
  want_ip=${!ip_var:-}

  # if Terraform didn’t output an IP (droplet not created) → skip
  [[ -z "$want_ip" || "$want_ip" == "null" ]] && continue

  sync_host "${HOSTPARTS[$res]}" "$want_ip"
done
echo "────────────────────────────────────────────────────────────────"

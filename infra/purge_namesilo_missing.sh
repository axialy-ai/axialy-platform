#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

# ---------------------------------------------------------------------
# 1. Collect current droplets (name ➜ public-IP) ----------------------
# ---------------------------------------------------------------------
#       name -> ui.axialy.ai
#       ip   -> 143.198.155.79
# ---------------------------------------------------------------------
mapfile -t DROPLET_INFO < <(
  doctl compute droplet list -o json |
  jq -r '.[] | .name as $n
                | .networks.v4[]?|select(.type=="public")|$n+","+ .ip_address'
)

# Build two grep-ready, *literal* (-F) lists
droplet_names=()
droplet_ips=()
for row in "${DROPLET_INFO[@]}"; do
  IFS=',' read -r n ip <<<"$row"
  droplet_names+=("$n")
  droplet_ips+=("$ip")
done

# Helpers that test membership with an exact (-x) fixed-string (-F) match
in_names() { printf '%s\n' "${droplet_names[@]}" | grep -Fxq "$1"; }
in_ips()   { printf '%s\n' "${droplet_ips[@]}"   | grep -Fxq "$1"; }

# ---------------------------------------------------------------------
# 2. Pull all NameSilo A records for the zone -------------------------
# ---------------------------------------------------------------------
readarray -t NS_RECORDS < <(
  curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=${KEY}&domain=${DOMAIN}" |
  xq -r '.namesilo.reply.resource_record[] 
         | select(.type=="A") 
         | "\(.record_id) \(.host) \(.value)"' )

# ---------------------------------------------------------------------
# 3. Delete any NameSilo A record that no longer matches --------------
#    a live droplet *by name*  OR  *by IP* ----------------------------
# ---------------------------------------------------------------------
for rec in "${NS_RECORDS[@]}"; do
  read -r RID HOST VALUE <<<"$rec"

  # NameSilo returns FQDNs.  Normalise just in case.
  HOST=${HOST%.}                       # strip trailing dot
  HOST=${HOST,,}                       # lower-case

  if ! in_names "$HOST" || ! in_ips "$VALUE"; then
    echo "Removing stale record $HOST ($RID ➜ $VALUE)"
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=xml&key=${KEY}&domain=${DOMAIN}&rrid=${RID}" >/dev/null
  fi
done

#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${NAMESILO_DOMAIN:?missing domain}"
KEY="${NAMESILO_API_KEY:?missing key}"

# --------------------------------------------------------------------
# Map host  ➜  desired IP address.  Tweak as needed or feed from TF.
# --------------------------------------------------------------------
declare -A DESIRED=(
  [""]="${ROOT_IP:?}"      # apex/@
  ["www"]="${ROOT_IP:?}"
  ["ui"]="${UI_IP:?}"
  ["api"]="${API_IP:?}"
  ["admin"]="${ADMIN_IP:?}"
)

# Convenience: call the NameSilo API and echo the JSON reply
ns() { curl -s "https://www.namesilo.com/api/$1?version=1&type=json&key=${KEY}&$2"; }

# Pull current zone                           ─────────────────────────
JSON=$(ns "dnsListRecords" "domain=${DOMAIN}")
jq -e '.namesilo.reply.code=="300"' <<<"$JSON" >/dev/null ||
  { echo "NameSilo error: $(jq -r '.namesilo.reply.detail' <<<"$JSON")"; exit 1; }

# Iterate over the hosts we care about        ─────────────────────────
for host in "${!DESIRED[@]}"; do
  want_ip="${DESIRED[$host]}"
  short="${host:-@}"                    # @ = apex in NameSilo
  fqn=$([[ -z "$host" ]] && echo "$DOMAIN" || echo "${host}.${DOMAIN}")

  # Find all *A* records for this FQDN
  mapfile -t recs < <(
    jq -r --arg h "$fqn" '.namesilo.reply.resource_record[]
          | select(.type=="A" and .host==$h)
          | "\(.record_id) \(.value)"' <<<"$JSON"
  )

  keep_found=false
  for rec in "${recs[@]}"; do
    id=${rec%% *}          # first field = record_id
    val=${rec#* }          # second     = value
    if [[ "$val" == "$want_ip" && $keep_found == false ]]; then
      # First matching record stays; treat any others as dupes
      keep_found=true
      continue
    fi
    echo "🗑  deleting ${fqn} → ${val} (rrid=${id})"
    ns "dnsDeleteRecord" "domain=${DOMAIN}&rrid=${id}" >/dev/null
  done

  # If nothing matched the IP we want, add it
  if ! $keep_found; then
    echo "➕ creating ${fqn} → ${want_ip}"
    ns "dnsAddRecord" \
       "domain=${DOMAIN}&rrtype=A&rrhost=${short}&rrvalue=${want_ip}&rrttl=3600" \
       >/dev/null
  fi
done

echo "✅  Zone ${DOMAIN} is now clean and correct."

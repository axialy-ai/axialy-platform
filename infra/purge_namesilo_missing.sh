#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# purge_namesilo_missing.sh
# -----------------------------------------------------------------------------
# Deletes any NameSilo A‑records that do **not** map to an existing DigitalOcean
# droplet.  Used by the GitHub Actions workflow before Terraform creates new
# droplets so that the zone is always in sync.
#
# Required environment variables (already set in the workflow):
#   - NAMESILO_API_KEY   – your NameSilo API key
#   - NAMESILO_DOMAIN    – e.g. "axialy.ai"
#   - DIGITALOCEAN_TOKEN – picked up by `doctl` (already authenticated earlier)
# -----------------------------------------------------------------------------
set -euo pipefail

API_KEY="${NAMESILO_API_KEY:?NAMESILO_API_KEY is required}"
DOMAIN="${NAMESILO_DOMAIN:?NAMESILO_DOMAIN is required}"

# -----------------------------------------------------------------------------
# 1. Collect current droplets + public IPv4 addresses from DigitalOcean
# -----------------------------------------------------------------------------
DROPLETS_JSON=$(doctl compute droplet list --output json)

declare -A DROPLET_IPS  # [fqdn]=ip

while IFS=$'\t' read -r name ip; do
  # Ensure the host we compare with NameSilo matches what Terraform creates.
  # If the droplet name already ends with the domain, keep it; otherwise append.
  if [[ "$name" == *."$DOMAIN" ]]; then
    fqdn="$name"
  else
    fqdn="$name.$DOMAIN"
  fi
  DROPLET_IPS["$fqdn"]="$ip"
done < <(
  echo "$DROPLETS_JSON" | jq -r '
    .[] | [.name, (.networks.v4[] | select(.type=="public").ip_address)] | @tsv'
)

# -----------------------------------------------------------------------------
# 2. Fetch NameSilo DNS records (JSON)
# -----------------------------------------------------------------------------
RECORDS_JSON=$(curl -s \
  "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}")

# -----------------------------------------------------------------------------
# 3. Remove any A‑record whose IP does not match a droplet
# -----------------------------------------------------------------------------
FILTER='.reply.resource_record[] | select(.type == "A")'

echo "$RECORDS_JSON" | jq -r --argjson keep "$(printf '%s\n' "${!DROPLET_IPS[@]}")" '
  '"$FILTER"' | "\(.record_id)\t\(.host)\t\(.value)"' | while IFS=$'\t' read -r rrid host value; do
  desired_ip="${DROPLET_IPS[$host]-}"
  if [[ -z "$desired_ip" || "$desired_ip" != "$value" ]]; then
    echo "Deleting stale record: $host → $value (rrid=$rrid)"
    curl -s \
      "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${API_KEY}&domain=${DOMAIN}&rrid=${rrid}" \
      | jq -e '.reply.code == 300' > /dev/null \
      || echo "WARNING: deletion failed for rrid=$rrid"
  fi
done

echo "✓ NameSilo zone purged – only active droplets remain."

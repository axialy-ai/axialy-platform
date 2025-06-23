#!/usr/bin/env bash
set -euo pipefail

API="https://www.namesilo.com/api"
DOMAIN="${NAMESILO_DOMAIN}"
KEY="${NAMESILO_API_KEY}"

# pull current A-records
xml="$(curl -s "${API}/dnsListRecords?version=1&type=xml&key=${KEY}&domain=${DOMAIN}")"

# extract their record-ids
mapfile -t ids < <(xmlstarlet sel -t -m '//resource_record[type="A"]' -v 'record_id' -n <<<"$xml")

# delete each one
for id in "${ids[@]}"; do
  curl -s \
    "${API}/dnsDeleteRecord?version=1&type=xml&key=${KEY}&domain=${DOMAIN}&rrid=${id}" \
    >/dev/null
done

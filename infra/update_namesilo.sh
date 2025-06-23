#!/usr/bin/env bash
set -euo pipefail

KEY="${NAMESILO_API_KEY:?Missing NAMESILO_API_KEY}"
DOMAIN="${NAMESILO_DOMAIN:?Missing NAMESILO_DOMAIN}"

json_records() {
  curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=${KEY}&domain=${DOMAIN}" |
    jq -c '.namesilo.response.resource_record
           | if type=="array" then .
             elif type=="object" then [.]
             else []
             end'
}

upsert() {
  local rrhost="$1" ip="$2" jq_filter ids recs
  if [[ -z "$rrhost" ]]; then
    jq_filter='(.host=="'"$DOMAIN"'" or .host=="@")'
  else
    jq_filter='.host=="'"$rrhost.$DOMAIN"'"'
  fi

  recs=$(json_records)
  ids=$(jq -r '[.][] | select(.type=="A" and '"$jq_filter"') | .record_id' <<<"$recs")

  for id in $ids; do
    curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&rrid=${id}" >/dev/null
  done

  [[ -z "$rrhost" ]] && host_param="" || host_param="rrhost=${rrhost}&"
  curl -s "https://www.namesilo.com/api/dnsAddRecord?version=1&type=json&key=${KEY}&domain=${DOMAIN}&${host_param}rrvalue=${ip}&rrtype=A&rrttl=3600" >/dev/null
}

ips_json=$(terraform -chdir=infra output -json droplet_ips)
upsert "admin" "$(jq -r '.admin' <<<"$ips_json")"
upsert "ui"    "$(jq -r '.ui'    <<<"$ips_json")"
upsert "api"   "$(jq -r '.api'   <<<"$ips_json")"
upsert "www"   "$(jq -r '.root'  <<<"$ips_json")"
upsert ""      "$(jq -r '.root'  <<<"$ips_json")"

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Update (or create) the exact A-records we need, deleting *all* stale ones.
# ---------------------------------------------------------------------------
set -euo pipefail

KEY="$NAMESILO_API_KEY"
DOMAIN="$NAMESILO_DOMAIN"
TTL=3600

api() {
  local endpoint="$1"; shift
  curl -s "https://www.namesilo.com/api/${endpoint}?version=1&type=json&key=${KEY}&domain=${DOMAIN}&$*"
}

# ---------- delete EVERY existing A-record for a host ----------
purge_host() {
  local RRHOST="$1"              # "" == apex
  echo "▶ Purging host '${RRHOST:-<apex>}' …"

  # Pull list → grab all matching record_ids
  local RRIDS
  RRIDS=$(api dnsListRecords | jq -r \
    --arg h "$RRHOST" --arg d "$DOMAIN" '
      .namesilo.response.resource_record[]
      | select(.type=="A"
               and ( ($h=="" and .host==$d)                       # apex
                     or (.host==$h+"."+$d) ) )                    # sub-host
      | .record_id')

  if [[ -z "$RRIDS" ]]; then
    echo "   ↳ nothing to delete"
    return
  fi

  # Delete each record id
  while IFS= read -r rrid; do
    echo "   ↳ deleting rrid=$rrid"
    api dnsDeleteRecord "rrid=${rrid}" > /dev/null
  done <<< "$RRIDS"
}

# ---------- add a single new A-record ----------
add_record() {
  local RRHOST="$1" IP="$2"
  echo "▶ Adding host '${RRHOST:-<apex>}' -> $IP"
  if [[ -z "$RRHOST" ]]; then
    api dnsAddRecord "rrvalue=${IP}&rrtype=A&rrttl=${TTL}" > /dev/null
  else
    api dnsAddRecord "rrhost=${RRHOST}&rrvalue=${IP}&rrtype=A&rrttl=${TTL}" > /dev/null
  fi
}

# ---------- fetch droplet IPs from Terraform output ----------
IPS=$(terraform -chdir=infra output -json droplet_ips)
ADMIN_IP=$(jq -r '.admin' <<< "$IPS")
UI_IP=$(jq -r '.ui'    <<< "$IPS")
API_IP=$(jq -r '.api'   <<< "$IPS")
ROOT_IP=$(jq -r '.root' <<< "$IPS")

# ---------- one-shot purge-then-add for each host ----------
for host in "" www api ui admin; do
  case $host in
    "")    NEW_IP="$ROOT_IP"   ;;
    www)   NEW_IP="$ROOT_IP"   ;;  # same IP as apex
    api)   NEW_IP="$API_IP"    ;;
    ui)    NEW_IP="$UI_IP"     ;;
    admin) NEW_IP="$ADMIN_IP"  ;;
  esac

  purge_host "$host"
  add_record "$host" "$NEW_IP"
done

echo "✅ NameSilo DNS now has exactly the records we expect."

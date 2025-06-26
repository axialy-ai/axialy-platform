#!/usr/bin/env bash
# Sync already-existing DO resources into the TF state file (idempotent).
set -eo pipefail
cd "$(dirname "$0")"

state_has () { [ -f terraform.tfstate ] && terraform state list | grep -q "^$1$"; }

PID=$(doctl projects list --format ID,Name --no-header | awk '$2=="Axialy"{print $1; exit}')
if [[ -n "$PID" ]] && ! state_has digitalocean_project.axialy ; then
  terraform import digitalocean_project.axialy "$PID"
fi

CID=$(doctl databases list --format ID,Name --no-header | awk '$2=="axialy-mysql"{print $1; exit}')
if [[ -n "$CID" ]]; then
  state_has digitalocean_database_cluster.mysql || \
    terraform import digitalocean_database_cluster.mysql "$CID"

  declare -A DBS=( ["ui"]="Axialy_UI" ["admin"]="Axialy_Admin" )
  for RES in "${!DBS[@]}"; do
    DB="${DBS[$RES]}"
    if doctl databases db list "$CID" --format Name --no-header | grep -qw "$DB" \
       && ! state_has "digitalocean_database_db.${RES}" ; then
      terraform import "digitalocean_database_db.${RES}" "${CID},${DB}"
    fi
  done
fi

declare -A HOSTS=( ["root"]="axialy.ai" ["ui"]="ui.axialy.ai" \
                   ["api"]="api.axialy.ai" ["admin"]="admin.axialy.ai" )
for RES in "${!HOSTS[@]}"; do
  NAME="${HOSTS[$RES]}"
  DID=$(doctl compute droplet list --format ID,Name --no-header | awk -v n="$NAME" '$2==n{print $1; exit}')
  if [[ -n "$DID" ]] && ! state_has "digitalocean_droplet.sites[\"${RES}\"]" ; then
    terraform import "digitalocean_droplet.sites[\"${RES}\"]" "$DID"
  fi
done

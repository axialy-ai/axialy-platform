# infra/import_existing.sh
#!/usr/bin/env bash
set -eo pipefail

state_has () { [ -f terraform.tfstate ] && terraform state list | grep -q "^$1$"; }

cd "$(dirname "$0")"

# Project
PID=$(doctl projects list --format ID,Name --no-header | awk '$2=="Axialy"{print $1; exit}')
if [ -n "$PID" ] && ! state_has digitalocean_project.axialy ; then
  terraform import digitalocean_project.axialy "$PID"
fi

# Managed MySQL cluster + two DBs
CID=$(doctl databases list --format ID,Name --no-header | awk '$2=="axialy-db-cluster"{print $1; exit}')
if [ -n "$CID" ]; then
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

# Droplets
declare -A DROPS=( ["ui"]="ui.axialy.ai" ["api"]="api.axialy.ai" ["admin"]="admin.axialy.ai" ["root"]="axialy.ai" )
for RES in "${!DROPS[@]}"; do
  NAME="${DROPS[$RES]}"
  DID=$(doctl compute droplet list --format ID,Name --no-header | awk -v n="$NAME" '$2==n{print $1; exit}')
  if [ -n "$DID" ] && ! state_has "digitalocean_droplet.${RES}" ; then
    terraform import "digitalocean_droplet.${RES}" "$DID"
  fi
done

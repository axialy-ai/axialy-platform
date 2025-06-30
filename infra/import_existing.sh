#!/usr/bin/env bash
#  import_existing.sh
#  A super-small helper: if the DB cluster or admin droplet already
#  exist, import them into the fresh Terraform state so that every
#  workflow run is idempotent.

set -eo pipefail
cd "$(dirname "$0")"

state_has () { [ -f terraform.tfstate ] && terraform state list | grep -q "^$1$"; }

# Import the project if it’s already there
PID=$(doctl projects list --format ID,Name --no-header | awk '$2=="Axialy"{print $1; exit}')
if [[ -n $PID ]] && ! state_has digitalocean_project.axialy ; then
  terraform import digitalocean_project.axialy "$PID"
fi

# Import the DB cluster (and its two DBs) if they pre-exist
CID=$(doctl databases list --format ID,Name --no-header | awk '$2=="axialy-db-cluster"{print $1; exit}')
if [[ -n $CID ]]; then
  state_has digitalocean_database_cluster.mysql || \
    terraform import digitalocean_database_cluster.mysql "$CID"

  for NAME in Axialy_Admin Axialy_UI; do
    RES=$( [[ $NAME == Axialy_Admin ]] && echo admin || echo ui )
    if doctl databases db list "$CID" --format Name --no-header | grep -qw "$NAME" \
       && ! state_has "digitalocean_database_db.${RES}"; then
      terraform import "digitalocean_database_db.${RES}" "${CID},${NAME}"
    fi
  done
fi

# Import the admin droplet if it already exists
DID=$(doctl compute droplet list --format ID,Name --no-header \
        | awk '$2=="admin.axialy.ai"{print $1; exit}')
if [[ -n $DID ]] && ! state_has digitalocean_droplet.admin ; then
  terraform import digitalocean_droplet.admin "$DID"
fi

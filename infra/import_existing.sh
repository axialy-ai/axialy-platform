#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  import_existing.sh
#  Idempotently imports any already-existing Axialy Admin resources
#  into the fresh Terraform state *and* guarantees that the provider
#  plugins are downloaded before we touch the state.
# ---------------------------------------------------------------------------

set -euo pipefail
cd "$(dirname "$0")"   # → infra/

##############################################################################
# 0 ▸ Make sure the DigitalOcean provider is installed
##############################################################################
if [ ! -d .terraform ] || [ ! -f .terraform.lock.hcl ]; then
  #   • -backend=false → no need to reach the remote backend yet
  #   • -input=false   → non-interactive (CI friendly)
  terraform init -backend=false -input=false -upgrade=false >/dev/null
fi

##############################################################################
# Helper: does the current state already contain a given resource?
##############################################################################
state_has() {
  # If there is no state file yet, obviously nothing is imported
  [[ -f terraform.tfstate ]] || return 1
  terraform state list | grep -q "^$1$"
}

##############################################################################
# 1 ▸ DigitalOcean project  (name: "Axialy")
##############################################################################
PID=$(doctl projects list --format ID,Name --no-header | awk '$2=="Axialy"{print $1; exit}')
if [[ -n $PID ]] && ! state_has digitalocean_project.axialy ; then
  terraform import digitalocean_project.axialy "$PID"
fi

##############################################################################
# 2 ▸ Managed MySQL cluster  +  its two databases
##############################################################################
CID=$(doctl databases list --format ID,Name --no-header | awk '$2=="axialy-db-cluster"{print $1; exit}')
if [[ -n $CID ]]; then
  state_has digitalocean_database_cluster.mysql || \
    terraform import digitalocean_database_cluster.mysql "$CID"

  # Axialy_Admin  /  Axialy_UI
  for NAME in Axialy_Admin Axialy_UI; do
    RES=$([[ $NAME == Axialy_Admin ]] && echo admin || echo ui)
    if doctl databases db list "$CID" --format Name --no-header | grep -qw "$NAME" \
       && ! state_has "digitalocean_database_db.${RES}"; then
      terraform import "digitalocean_database_db.${RES}" "${CID},${NAME}"
    fi
  done
fi

##############################################################################
# 3 ▸ Admin droplet  (hostname: admin.axialy.ai)
##############################################################################
DID=$(doctl compute droplet list --format ID,Name --no-header \
        | awk '$2=="admin.axialy.ai"{print $1; exit}')
if [[ -n $DID ]] && ! state_has digitalocean_droplet.admin ; then
  terraform import digitalocean_droplet.admin "$DID"
fi

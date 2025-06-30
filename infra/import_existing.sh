#!/usr/bin/env bash
set -euo pipefail

# Import project (always exists – ID is hard-coded here)
terraform import -no-color digitalocean_project.axialy d895904a-4fbb-4492-8038-02071ab8f75b || true

# Import cluster if it’s already in the account
CID=$(doctl databases list --format ID,Name --no-header |
      awk '$2=="axialy-db-cluster"{print $1; exit}')
if [[ -n "$CID" ]]; then
  terraform import -no-color digitalocean_database_cluster.mysql "$CID" || true
fi

# Import droplet if the hostname exists
DID=$(doctl compute droplet list --format ID,Name --no-header |
      awk '$2=="admin.axialy.ai"{print $1; exit}')
if [[ -n "$DID" ]]; then
  terraform import -no-color digitalocean_droplet.admin "$DID" || true
fi

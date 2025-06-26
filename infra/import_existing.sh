#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  infra/import_existing.sh
#  Safely imports *only* those DigitalOcean resources that actually exist.
#  Missing IDs are skipped instead of killing the pipeline.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TF="terraform -chdir=${SCRIPT_DIR}"

# --- utility ---------------------------------------------------------------
import_if_exists () {
  local tfaddr=$1   # terraform address, e.g. digitalocean_firewall.web
  local real_id=$2  # remote ID, e.g. f1d2d2f924…

  if [[ -z "$real_id" || "$real_id" == "0" ]]; then
    echo "↩︎  $tfaddr – no ID configured, skipping."
    return
  fi

  # quick existence check via doctl (much faster than a failing terraform import)
  if doctl compute firewall get "$real_id" &>/dev/null \
        || doctl compute droplet  get "$real_id" &>/dev/null; then
    echo "⇢  Importing $tfaddr ($real_id)…"
    $TF import "$tfaddr" "$real_id"
  else
    echo "⚠️  $tfaddr – remote object '$real_id' not found, skipping."
  fi
}

# ---------------------------------------------------------------------------
#  DigitalOcean project (always exists once and for all)
# ---------------------------------------------------------------------------
$TF import digitalocean_project.axialy d895904a-4fbb-4492-8038-02071ab8f75b

# ---------------------------------------------------------------------------
#  Firewalls – **replace the placeholders with your real IDs once**, or leave
#  them empty to let Terraform create fresh firewalls automatically.
# ---------------------------------------------------------------------------
import_if_exists digitalocean_firewall.web f1d2d2f924e986ac86fdf7b36c94bcdf32beec15
import_if_exists digitalocean_firewall.db  7c222fb2927d828af22f592134e8932480637c0d

# ---------------------------------------------------------------------------
#  Droplets – uncomment & fill in if you already have live droplets.
# ---------------------------------------------------------------------------
# import_if_exists digitalocean_droplet.ui    123456789
# import_if_exists digitalocean_droplet.api   987654321
# import_if_exists digitalocean_droplet.admin 1122334455
# import_if_exists digitalocean_droplet.root  5566778899

echo "✅  Import step finished (skips are OK)."

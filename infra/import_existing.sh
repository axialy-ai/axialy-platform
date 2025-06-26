#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  infra/import_existing.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TF="terraform -chdir=${SCRIPT_DIR}"

# ────────────────────────────────────────────────────────────────────────────
#  DigitalOcean project
# ────────────────────────────────────────────────────────────────────────────
${TF} import digitalocean_project.axialy d895904a-4fbb-4492-8038-02071ab8f75b

# ────────────────────────────────────────────────────────────────────────────
#  Firewalls   (IDs are examples – swap for your real ones once, then commit)
# ────────────────────────────────────────────────────────────────────────────
${TF} import digitalocean_firewall.web f1d2d2f924e986ac86fdf7b36c94bcdf32beec15
${TF} import digitalocean_firewall.db  7c222fb2927d828af22f592134e8932480637c0d

# ────────────────────────────────────────────────────────────────────────────
#  Droplets    (uncomment whichever actually exist)
# ────────────────────────────────────────────────────────────────────────────
# ${TF} import digitalocean_droplet.ui     123456789
# ${TF} import digitalocean_droplet.api    987654321
# ${TF} import digitalocean_droplet.admin  1122334455
# ${TF} import digitalocean_droplet.root   5566778899

echo "✅  All resource imports completed successfully."

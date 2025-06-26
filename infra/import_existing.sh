#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  infra/import_existing.sh
#
#  One-off helper to pull **real, pre-existing resources** into Terraform
#  state.  **Only resources belong here – never data sources.**
#
#  Run automatically by the CI workflow, but it’s safe to execute locally
#  too.  Idempotent: if a resource is already in state, Terraform just skips
#  it.
# ---------------------------------------------------------------------------

set -euo pipefail

# Always run Terraform from the infra/ directory no matter where the script
# is launched.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TF="terraform -chdir=${SCRIPT_DIR}"

# ────────────────────────────────────────────────────────────────────────────
#  DigitalOcean project
# ────────────────────────────────────────────────────────────────────────────
# Replace the ID below with **your** project UUID once and commit it; after
# that the import becomes a no-op.
${TF} import \
  digitalocean_project.axialy \
  d895904a-4fbb-4492-8038-02071ab8f75b

# ────────────────────────────────────────────────────────────────────────────
#  Firewalls – these are *resources*, not the `data.digitalocean_firewalls`
#  lookup that blew up the last run.  Uncomment / edit the examples as
#  required, or delete the section entirely if you manage firewalls some
#  other way.
# ────────────────────────────────────────────────────────────────────────────
# ${TF} import digitalocean_firewall.web   f1d2d2f924e986ac86fdf7b36c94bcdf32beec15
# ${TF} import digitalocean_firewall.db    7c222fb2927d828af22f592134e8932480637c0d

# ────────────────────────────────────────────────────────────────────────────
#  Droplets – same idea; comment-in only the ones that really exist.
# ────────────────────────────────────────────────────────────────────────────
# ${TF} import digitalocean_droplet.ui     123456789
# ${TF} import digitalocean_droplet.api    987654321
# ${TF} import digitalocean_droplet.admin  1122334455
# ${TF} import digitalocean_droplet.root   5566778899

echo "✅  All resource imports completed successfully."

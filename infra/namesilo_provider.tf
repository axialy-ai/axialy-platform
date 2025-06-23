# infra/namesilo_provider.tf
#
# Terraform only needs the provider block so that `terraform init`
# can download the plugin.  All DNS changes are still done by
# infra/update_namesilo.sh & infra/purge_namesilo_missing.sh.

provider "namesilo" {
  # The API key comes from the GitHub-Actions environment variable
  # NAMESILO_API_KEY that you already set in the workflow.
  api_key = var.namesilo_api_key
}

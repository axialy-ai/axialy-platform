################################################################################
# Purge every A record in NameSilo before Terraform creates fresh ones
# (requires NAMESILO_DOMAIN and NAMESILO_API_KEY already exported in the runner)
################################################################################

locals {
  list_cmd = <<-EOCMD
    set -eo pipefail
    curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=$NAMESILO_API_KEY&domain=$NAMESILO_DOMAIN" |
      jq -r '.reply.resource_record[] | select(.type=="A") | .record_id'
  EOCMD

  delete_cmd = <<-EOCMD
    set -eo pipefail
    for id in $("${local.list_cmd}"); do
      curl -s "https://www.namesilo.com/api/dnsDeleteRecord?version=1&type=json&key=$NAMESILO_API_KEY&domain=$NAMESILO_DOMAIN&rrid=$id" \
        | jq -e '.reply.code==300' >/dev/null
      echo "‣ deleted $id"
    done
  EOCMD
}

# always triggers – runs once per `terraform apply`
resource "null_resource" "purge_namesilo_a" {
  triggers = {
    run_id = timestamp()    # guarantees this null_resource executes on every plan/apply
  }

  provisioner "local-exec" {
    command     = local.delete_cmd
    interpreter = ["/usr/bin/env", "bash", "-c"]
  }
}

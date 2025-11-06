package policy.labels

import data.tfplan

required := {"env", "owner"}

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "google_storage_bucket"
  missing := {k | k := required[_]; not r.after.labels[k]}
  count(missing) > 0
  msg := sprintf("GCP: Bucket %s missing labels: %v", [r.address, missing])
}

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "azurerm_resource_group"
  missing := {k | k := required[_]; not r.after.tags[k]}
  count(missing) > 0
  msg := sprintf("Azure: Resource group %s missing tags: %v", [r.address, missing])
}

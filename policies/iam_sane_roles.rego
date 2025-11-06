package policy.iam

import data.tfplan

# Light sanity checks: avoid Owner/Admin level grants in code.

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "google_project_iam_member"
  contains(lower(r.after.role), "owner")
  msg := sprintf("GCP: Avoid project Owner in %s (%s)", [r.address, r.after.role])
}

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "azurerm_role_assignment"
  lower(r.after.role_definition_name) == "owner"
  msg := sprintf("Azure: Avoid Owner role in %s", [r.address])
}

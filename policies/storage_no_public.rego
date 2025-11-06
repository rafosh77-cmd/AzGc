package policy.storage

import data.tfplan

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "google_storage_bucket_iam_binding"
  r.after.role == "roles/storage.objectViewer"
  some m
  m := r.after.members[_]
  startswith(m, "allUsers")
  msg := sprintf("GCP: Bucket IAM binding %s makes bucket public via %s", [r.address, m])
}

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "azurerm_storage_container"
  lower(r.after.container_access_type) != "private"
  msg := sprintf("Azure: Storage container %s must be private", [r.address])
}

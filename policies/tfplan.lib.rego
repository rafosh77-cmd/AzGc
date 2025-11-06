package tfplan

# Helpers for Terraform plan JSON (v0.12+)
# Returns an array of planned resources with a simplified shape.
planned_resources[r] {
  rc := input.resource_changes[_]
  rc.change.actions[_] != "delete"
  dr := rc.change.after
  r := {
    "address": rc.address,
    "type": rc.type,
    "name": rc.name,
    "after": dr
  }
}

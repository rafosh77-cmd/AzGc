package policy.network

import data.tfplan

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "google_compute_firewall"
  lower(r.after.direction) == "ingress"
  r.after.source_ranges[_] == "0.0.0.0/0"
  # Warn when allowing anything other than 443
  some rule
  rule := r.after.allowed[_]
  some p
  p := rule.ports[_]
  p != "443"
  msg := sprintf("GCP: Firewall %s allows 0.0.0.0/0 to port %s (non-443)", [r.address, p])
}

deny[msg] {
  r := tfplan.planned_resources[_]
  r.type == "azurerm_network_security_rule"
  lower(r.after.direction) == "inbound"
  lower(r.after.access) == "allow"
  r.after.source_address_prefix == "*"
  r.after.destination_port_range != "443"
  msg := sprintf("Azure: NSG rule %s allows ANY inbound to non-443", [r.address])
}

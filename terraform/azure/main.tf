terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = "be493a94-0958-4cab-9e43-e3dcbd7828c4"
  tenant_id       = "9f0e803b-780b-4457-b633-af64c3d4e962"
}



locals {
  tags = { env = "lab", owner = "lab" }
}

resource "azurerm_resource_group" "rg" {
  name     = "AzGc"
  location = var.location
  tags     = local.tags
}

resource "random_string" "rand" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}stor${random_string.rand.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
  tags = local.tags
}

resource "azurerm_storage_container" "private" {
  name                  = "private"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Minimal NSG with no overly broad rules (compliant baseline)
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# Example safe inbound 443 rule limited to RFC1918 (edit as needed)
resource "azurerm_network_security_rule" "allow_https_private" {
  name                        = "allow-https-private"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

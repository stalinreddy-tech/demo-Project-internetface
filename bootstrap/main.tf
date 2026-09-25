# =============================================================================
# Bootstrap: Azure Storage Account for Terraform Remote State
# Run this ONCE (or re-apply when adding containers). Creates the state backend.
# Containers: tfstate-dev, tfstate-qa, tfstate-prod (one blob key per env).
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  # Avoid auto-registering every RP (needs Owner; can also fail with EOF/timeouts).
  # Register only what you need once (see docs) or ask a subscription Owner.
  skip_provider_registration = true
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate-internetface"
  location = var.location

  tags = {
    Purpose     = "terraform-remote-state"
    ManagedBy   = "terraform-bootstrap"
    Environment = "shared"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  # Harden state storage: no public blob access; use Azure AD + keys carefully
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Purpose     = "terraform-remote-state"
    ManagedBy   = "terraform-bootstrap"
    Environment = "shared"
  }
}

resource "azurerm_storage_container" "tfstate" {
  for_each = toset(["dev", "qa", "prod"])

  name                  = "tfstate-${each.key}"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

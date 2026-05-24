data "azuread_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

resource "terraform_data" "validate_key_vault_secret_handoff" {
  input = {
    create_client_secret = var.create_client_secret
    key_vault_id         = var.key_vault_id
  }

  lifecycle {
    precondition {
      condition     = !var.create_client_secret || var.key_vault_id != null
      error_message = "key_vault_id is required when create_client_secret is true so the generated secret can be handed off through Key Vault."
    }
  }
}

resource "azuread_service_principal" "microsoft_graph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

locals {
  application_owners = length(var.application_owners) > 0 ? var.application_owners : [data.azuread_client_config.current.object_id]
}

resource "azuread_application" "onboarding" {
  display_name = var.application_display_name
  owners       = local.application_owners

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    dynamic "resource_access" {
      for_each = var.graph_application_permissions

      content {
        id   = azuread_service_principal.microsoft_graph.app_role_ids[resource_access.value]
        type = "Role"
      }
    }
  }
}

resource "azuread_service_principal" "onboarding" {
  client_id = azuread_application.onboarding.client_id
  owners    = local.application_owners
}

resource "azuread_application_password" "onboarding" {
  count = var.create_client_secret ? 1 : 0

  application_id    = azuread_application.onboarding.id
  display_name      = var.client_secret_display_name
  end_date_relative = var.client_secret_end_date_relative

  depends_on = [
    terraform_data.validate_key_vault_secret_handoff
  ]
}

resource "azurerm_key_vault_secret" "graph_client_secret" {
  count = var.create_client_secret ? 1 : 0

  name         = var.key_vault_secret_name
  value        = azuread_application_password.onboarding[0].value
  key_vault_id = var.key_vault_id
  content_type = "Microsoft Graph client secret for onboarding Functions app"
}

resource "azuread_app_role_assignment" "graph_permissions" {
  for_each = var.graph_application_permissions

  app_role_id         = azuread_service_principal.microsoft_graph.app_role_ids[each.value]
  principal_object_id = azuread_service_principal.onboarding.object_id
  resource_object_id  = azuread_service_principal.microsoft_graph.object_id
}

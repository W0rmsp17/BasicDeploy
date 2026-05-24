resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  normalized_prefix = lower(replace("${var.workload_name}-${var.environment_name}", "/[^a-zA-Z0-9]/", ""))
  resource_suffix   = random_string.suffix.result
  storage_name      = substr("${local.normalized_prefix}${local.resource_suffix}", 0, 24)
  key_vault_name    = substr("kv-${var.workload_name}-${var.environment_name}-${local.resource_suffix}", 0, 24)
  function_name     = substr("func-${var.workload_name}-${var.environment_name}-${local.resource_suffix}", 0, 60)
  app_plan_name     = "plan-${var.workload_name}-${var.environment_name}-${local.resource_suffix}"
  app_insights_name = "appi-${var.workload_name}-${var.environment_name}-${local.resource_suffix}"
  graph_secret_id   = var.graph_client_secret_key_vault_secret_id != null ? var.graph_client_secret_key_vault_secret_id : azurerm_key_vault_secret.graph_client_secret[0].id
  approval_base_url = trimsuffix(var.approval_base_url, "/")
}

resource "azurerm_resource_group" "onboarding" {
  name     = "rg-${var.workload_name}-${var.environment_name}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "onboarding" {
  name                            = local.storage_name
  resource_group_name             = azurerm_resource_group.onboarding.name
  location                        = azurerm_resource_group.onboarding.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  tags                            = var.tags
}

resource "azurerm_storage_table" "onboarding_requests" {
  name                 = "OnboardingRequests"
  storage_account_name = azurerm_storage_account.onboarding.name
}

resource "azurerm_storage_queue" "create_user" {
  name                 = "create-user"
  storage_account_name = azurerm_storage_account.onboarding.name
}

resource "azurerm_key_vault" "onboarding" {
  name                       = local.key_vault_name
  resource_group_name        = azurerm_resource_group.onboarding.name
  location                   = azurerm_resource_group.onboarding.location
  tenant_id                  = var.graph_tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
}

resource "azurerm_key_vault_secret" "graph_client_secret" {
  count = var.graph_client_secret_key_vault_secret_id == null ? 1 : 0

  name         = "graph-client-secret"
  value        = var.graph_client_secret_value
  key_vault_id = azurerm_key_vault.onboarding.id
  content_type = "Microsoft Graph client secret for onboarding Functions app"

  lifecycle {
    precondition {
      condition     = var.graph_client_secret_value != null
      error_message = "graph_client_secret_value is required when graph_client_secret_key_vault_secret_id is not provided."
    }
  }
}

resource "azurerm_key_vault_secret" "approval_token_signing_key" {
  name         = "approval-token-signing-key"
  value        = var.approval_token_signing_key
  key_vault_id = azurerm_key_vault.onboarding.id
  content_type = "HMAC key for approval token signing"
}

resource "azurerm_service_plan" "onboarding" {
  name                = local.app_plan_name
  resource_group_name = azurerm_resource_group.onboarding.name
  location            = azurerm_resource_group.onboarding.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_application_insights" "onboarding" {
  name                = local.app_insights_name
  resource_group_name = azurerm_resource_group.onboarding.name
  location            = azurerm_resource_group.onboarding.location
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "onboarding" {
  name                = local.function_name
  resource_group_name = azurerm_resource_group.onboarding.name
  location            = azurerm_resource_group.onboarding.location

  service_plan_id            = azurerm_service_plan.onboarding.id
  storage_account_name       = azurerm_storage_account.onboarding.name
  storage_account_access_key = azurerm_storage_account.onboarding.primary_access_key
  https_only                 = true
  tags                       = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "dotnet-isolated"
    AzureWebJobsStorage                   = azurerm_storage_account.onboarding.primary_connection_string
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.onboarding.connection_string
    Approval__Provider                    = "Graph"
    Approval__BaseUrl                     = local.approval_base_url
    Approval__RecipientEmail              = var.approval_recipient_email
    Approval__SenderUserPrincipalName     = var.approval_sender_user_principal_name
    Approval__TokenSigningKey             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.approval_token_signing_key.id})"
    Graph__TenantId                       = var.graph_tenant_id
    Graph__ClientId                       = var.graph_client_id
    Graph__ClientSecret                   = "@Microsoft.KeyVault(SecretUri=${local.graph_secret_id})"
    Storage__OnboardingRequestsTableName  = azurerm_storage_table.onboarding_requests.name
    Provisioning__Provider                = "Graph"
    Provisioning__DefaultUserDomain       = var.default_user_domain
    Provisioning__CreateDisabledUsers     = tostring(var.create_disabled_users)
    Provisioning__LicenseAssignmentMode   = var.license_assignment_mode
    Provisioning__LicenseGroupId          = var.license_group_id
    WEBSITE_RUN_FROM_PACKAGE              = "1"
  }
}

resource "azurerm_role_assignment" "function_key_vault_secrets_user" {
  scope                = azurerm_key_vault.onboarding.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.onboarding.identity[0].principal_id
}

output "tenant_id" {
  description = "Target tenant ID."
  value       = data.azuread_client_config.current.tenant_id
}

output "application_client_id" {
  description = "Client ID for the onboarding app registration."
  value       = azuread_application.onboarding.client_id
}

output "application_object_id" {
  description = "Object ID for the onboarding app registration."
  value       = azuread_application.onboarding.object_id
}

output "service_principal_object_id" {
  description = "Object ID for the onboarding enterprise application service principal."
  value       = azuread_service_principal.onboarding.object_id
}

output "client_secret_key_vault_secret_id" {
  description = "Key Vault secret ID containing the generated Graph client secret."
  value       = try(azurerm_key_vault_secret.graph_client_secret[0].id, null)
}

output "granted_graph_application_permissions" {
  description = "Microsoft Graph application permissions assigned to the onboarding service principal."
  value       = sort(tolist(var.graph_application_permissions))
}

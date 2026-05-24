output "resource_group_name" {
  description = "Runtime resource group name."
  value       = azurerm_resource_group.onboarding.name
}

output "function_app_name" {
  description = "Function App name."
  value       = azurerm_linux_function_app.onboarding.name
}

output "function_app_default_hostname" {
  description = "Function App default hostname."
  value       = azurerm_linux_function_app.onboarding.default_hostname
}

output "key_vault_id" {
  description = "Runtime Key Vault resource ID."
  value       = azurerm_key_vault.onboarding.id
}

output "storage_account_name" {
  description = "Runtime Storage Account name."
  value       = azurerm_storage_account.onboarding.name
}

output "onboarding_requests_table_name" {
  description = "Onboarding request table name."
  value       = azurerm_storage_table.onboarding_requests.name
}

output "create_user_queue_name" {
  description = "Create user queue name."
  value       = azurerm_storage_queue.create_user.name
}

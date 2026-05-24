variable "workload_name" {
  type        = string
  description = "Short workload name used in Azure resource names."
}

variable "environment_name" {
  type        = string
  description = "Environment/client name used in Azure resource names."
}

variable "location" {
  type        = string
  description = "Azure region for deployed resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to Azure resources."
  default     = {}
}

variable "graph_tenant_id" {
  type        = string
  description = "Target tenant ID used for Graph app-only authentication."
}

variable "graph_client_id" {
  type        = string
  description = "Client ID for the Graph app registration."
}

variable "graph_client_secret_value" {
  type        = string
  description = "Graph app registration client secret value. Used in bootstrap mode to write the secret to Key Vault."
  default     = null
  nullable    = true
  sensitive   = true
}

variable "graph_client_secret_key_vault_secret_id" {
  type        = string
  description = "Existing Key Vault secret ID for the Graph client secret. Used in manual identity mode."
  default     = null
  nullable    = true
}

variable "approval_base_url" {
  type        = string
  description = "Public base URL used to generate approval links. Usually set after Function App hostname is known."
}

variable "approval_recipient_email" {
  type        = string
  description = "MSP/service desk approval recipient email address."
}

variable "approval_sender_user_principal_name" {
  type        = string
  description = "Actor-supplied sender mailbox UPN in the target tenant."
}

variable "approval_token_signing_key" {
  type        = string
  description = "Secret value used to sign approval tokens."
  sensitive   = true
}

variable "default_user_domain" {
  type        = string
  description = "Default user domain for generated UPNs."
}

variable "create_disabled_users" {
  type        = bool
  description = "Whether provisioned users should be created disabled."
  default     = true
}

variable "license_assignment_mode" {
  type        = string
  description = "License handling mode: None, DynamicGroup, or StaticGroup."
  default     = "None"

  validation {
    condition     = contains(["None", "DynamicGroup", "StaticGroup"], var.license_assignment_mode)
    error_message = "license_assignment_mode must be None, DynamicGroup, or StaticGroup."
  }
}

variable "license_group_id" {
  type        = string
  description = "Group object ID used when license_assignment_mode is StaticGroup."
  default     = ""
}

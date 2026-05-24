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
  description = "Initial public base URL used to generate approval links. Use a placeholder, then run the post-deploy app setting update."
  default     = "https://pending-post-deploy-update"
}

variable "approval_provider" {
  type        = string
  description = "Approval notification provider: Graph for email delivery or Logging for smoke tests."
  default     = "Graph"

  validation {
    condition     = contains(["Graph", "Logging"], var.approval_provider)
    error_message = "approval_provider must be Graph or Logging."
  }
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

variable "static_web_app_sku_tier" {
  type        = string
  description = "Azure Static Web Apps SKU tier for the Teams frontend."
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku_tier)
    error_message = "static_web_app_sku_tier must be Free or Standard."
  }
}

variable "static_web_app_sku_size" {
  type        = string
  description = "Azure Static Web Apps SKU size for the Teams frontend."
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku_size)
    error_message = "static_web_app_sku_size must be Free or Standard."
  }
}

variable "function_cors_allowed_origins" {
  type        = list(string)
  description = "Additional allowed CORS origins for the Function App. The Static Web Apps origin is added automatically."
  default = [
    "http://127.0.0.1:53000",
    "http://localhost:53000"
  ]
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

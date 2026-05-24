variable "environment_name" {
  type        = string
  description = "Short deployment environment name used in Azure resource names."
  default     = "client-dev"
}

variable "location" {
  type        = string
  description = "Azure region for the deployment."
  default     = "australiaeast"
}

variable "target_tenant_domain" {
  type        = string
  description = "Default user domain for the target tenant, for example contoso.onmicrosoft.com."
}

variable "msp_tenant_domain" {
  type        = string
  description = "MSP tenant domain used for tagging and deployment documentation."
  default     = ""
}

variable "graph_tenant_id" {
  type        = string
  description = "Target tenant ID."
}

variable "graph_client_id" {
  type        = string
  description = "Graph app registration client ID from bootstrap or manual identity mode."
}

variable "graph_client_secret_value" {
  type        = string
  description = "Graph client secret value for bootstrap testing. Prefer protected variable input."
  default     = null
  nullable    = true
  sensitive   = true
}

variable "graph_client_secret_key_vault_secret_id" {
  type        = string
  description = "Existing Key Vault secret ID containing the Graph client secret."
  default     = null
  nullable    = true
}

variable "approval_recipient_email" {
  type        = string
  description = "Approver mailbox."
}

variable "approval_base_url" {
  type        = string
  description = "Initial public base URL used in approval links. Defaults to a placeholder and should be updated post-deploy."
  default     = "https://pending-post-deploy-update"
}

variable "approval_provider" {
  type        = string
  description = "Approval notification provider: Graph or Logging."
  default     = "Graph"
}

variable "approval_sender_user_principal_name" {
  type        = string
  description = "Sender mailbox UPN in the target tenant."
}

variable "approval_token_signing_key" {
  type        = string
  description = "HMAC token signing key."
  sensitive   = true
}

variable "license_assignment_mode" {
  type        = string
  description = "License handling mode: None, DynamicGroup, or StaticGroup."
  default     = "DynamicGroup"
}

variable "license_group_id" {
  type        = string
  description = "Group object ID used only for StaticGroup mode."
  default     = ""
}

variable "application_display_name" {
  type        = string
  description = "Display name for the target tenant app registration used by the onboarding Functions app."
  default     = "m365-onboarding-functions"
}

variable "application_owners" {
  type        = list(string)
  description = "Optional object IDs of users or service principals that should own the application registration."
  default     = []
}

variable "create_client_secret" {
  type        = bool
  description = "Whether bootstrap should create a client secret for the app registration. Manual identity mode can set this to false."
  default     = true
}

variable "client_secret_display_name" {
  type        = string
  description = "Display name for the generated client secret."
  default     = "functions-local-or-keyvault-secret"
}

variable "client_secret_end_date_relative" {
  type        = string
  description = "Relative expiry for the generated client secret."
  default     = "2160h"
}

variable "key_vault_id" {
  type        = string
  description = "Existing Key Vault resource ID where the generated Graph client secret should be stored. Required when create_client_secret is true."
  default     = null
  nullable    = true
}

variable "key_vault_secret_name" {
  type        = string
  description = "Name of the Key Vault secret that stores the generated Graph client secret."
  default     = "graph-client-secret"
}

variable "graph_application_permissions" {
  type        = set(string)
  description = "Microsoft Graph application permissions to request and grant."
  default = [
    "Mail.Send",
    "User.ReadWrite.All",
    "GroupMember.ReadWrite.All"
  ]
}

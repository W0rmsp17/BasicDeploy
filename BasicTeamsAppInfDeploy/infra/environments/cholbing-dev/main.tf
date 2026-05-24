module "runtime" {
  source = "../../modules/runtime"

  workload_name       = "onboard"
  environment_name    = var.environment_name
  location            = var.location
  graph_tenant_id     = var.graph_tenant_id
  graph_client_id     = var.graph_client_id
  default_user_domain = var.target_tenant_domain

  graph_client_secret_value               = var.graph_client_secret_value
  graph_client_secret_key_vault_secret_id = var.graph_client_secret_key_vault_secret_id
  approval_recipient_email                = var.approval_recipient_email
  approval_base_url                       = var.approval_base_url
  approval_provider                       = var.approval_provider
  approval_sender_user_principal_name     = var.approval_sender_user_principal_name
  approval_token_signing_key              = var.approval_token_signing_key
  license_assignment_mode                 = var.license_assignment_mode
  license_group_id                        = var.license_group_id

  tags = {
    workload     = "m365-onboarding"
    environment  = var.environment_name
    targetTenant = var.target_tenant_domain
    mspTenant    = var.msp_tenant_domain
  }
}

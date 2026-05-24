# Bootstrap App Registration

This Terraform module creates the target tenant app registration used by the onboarding Azure Functions app.

It is intended for bootstrap mode, where the deployer has enough Microsoft Entra privilege to create app registrations and grant Microsoft Graph application permissions.

## What It Creates

- App registration.
- Enterprise application/service principal.
- Optional client secret.
- Key Vault secret containing the generated client secret.
- Required Microsoft Graph application permission declarations.
- Microsoft Graph app role assignments for admin consent.

Default Graph application permissions:

- `Mail.Send`
- `User.ReadWrite.All`
- `GroupMember.ReadWrite.All`

## What It Does Not Create

- Exchange Online sender mailbox.
- Exchange application access policy restricting `Mail.Send` to the sender mailbox.
- Azure Function App resources.
- Key Vault resource creation.

The deployment actor supplies the sender mailbox UPN. The mailbox itself and any mailbox restriction should be handled as tenant setup steps or by a later Exchange/Graph script.

## Secret Handoff

When `create_client_secret` is `true`, the module requires `key_vault_id`.

The generated app registration password is stored in Key Vault and is not output as a raw secret. The module outputs the Key Vault secret ID so the Function App can use a Key Vault reference.

The secret value still exists in Terraform state because Terraform creates and manages the app registration password and Key Vault secret. This is acceptable for bootstrap mode when state is protected. Production deployments should use a secure remote backend or manual identity mode.

## Required Deployment Access

The account or service principal running this bootstrap needs permission to:

- Create/update app registrations.
- Create service principals.
- Create app role assignments for Microsoft Graph.

For a user principal, this typically means a highly privileged Entra role such as Global Administrator or Application Administrator, with Privileged Role Administrator or Global Administrator commonly required for granting Microsoft Graph application permissions.

For a service principal, the AzureAD provider documents app role assignment requirements such as `AppRoleAssignment.ReadWrite.All` plus suitable read permissions, or broader application/directory write permissions.

## Usage

```powershell
terraform init
terraform plan
terraform apply
```

After apply, capture:

- `tenant_id` -> `Graph__TenantId`
- `application_client_id` -> `Graph__ClientId`
- `client_secret_key_vault_secret_id` -> `Graph__ClientSecret` Key Vault reference

Function app setting example:

```text
Graph__ClientSecret=@Microsoft.KeyVault(SecretUri=<client_secret_key_vault_secret_id>)
```

The approval sender mailbox UPN is not created here. Enter the actor-supplied value as:

```text
Approval__SenderUserPrincipalName=onboarding@CholbingDevoutlook.onmicrosoft.com
```

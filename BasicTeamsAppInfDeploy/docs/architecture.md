# Serverless Microsoft 365 User Onboarding

## Purpose

This project is a reusable starter solution for basic Microsoft 365 user onboarding from Microsoft Teams. It is intended for MSP-style scenarios where each client tenant owns the automation that provisions users in its own tenant, while an MSP operator or service desk approves the request by email.

The goal is to demonstrate a low-cost, secure, serverless Azure design that can be deployed per client tenant using Terraform and customized through .NET extension points.

## Design Goals

- Deploy per client tenant to avoid unnecessary cross-tenant runtime permissions.
- Keep Microsoft Graph permissions inside the target tenant.
- Use serverless services with low idle cost.
- Keep the default workflow simple enough to understand, deploy, and extend.
- Preserve an auditable request and approval history.
- Separate form submission, approval, and user creation into clear steps.
- Prefer group-based license assignment over direct license SKU handling.

## Non-Goals

- Replace a full identity governance platform.
- Build a complete HR onboarding system.
- Support every MSP client workflow in the first implementation.
- Centralize privileged Graph permissions in the MSP tenant.
- Directly assign Microsoft 365 license SKUs in the MVP.

## High-Level Flow

```text
Teams onboarding tab
  -> SubmitOnboardingRequest HTTP function
  -> Onboarding request stored in Azure Table Storage
  -> Approval email sent to MSP/service desk

Approval link
  -> ApproveOnboardingRequest or DenyOnboardingRequest HTTP function
  -> Approved requests enqueue a CreateUser command

Queue trigger
  -> CreateUser function
  -> Microsoft Graph creates the user in the target tenant
  -> Optional group assignment triggers group-based licensing
  -> Request status is updated for audit
```

## Tenant Boundary

The solution is deployed into the target client environment. The Teams app, Azure Functions, storage account, and Graph application permissions are all tenant-local to the client.

The MSP participates as an approver through email. This keeps the first version simple and avoids requiring the MSP tenant to hold broad delegated or application permissions over client tenants.

For the test deployment:

| Role | Tenant |
| --- | --- |
| Target/client tenant | `CholbingDevoutlook.onmicrosoft.com` |
| MSP/approver tenant | `plutonix.onmicrosoft.com` |

The target tenant owns the runtime and Microsoft Graph provisioning permissions. The MSP tenant only receives approval email in the MVP.

## Provisioning Modes

The deployment should support two setup paths.

### Bootstrap Mode

Bootstrap mode is for MSPs or lab deployments where the implementer can use highly privileged setup access during deployment.

In this mode, Terraform and setup scripts may create or configure:

- Azure resource group and serverless runtime resources.
- Managed identity and Azure RBAC assignments.
- Key Vault secrets or references.
- App registration or service principal used for Graph provisioning.
- Required Microsoft Graph application permissions.
- Admin consent in the target tenant.
- Dedicated sender mailbox configuration for approval emails.
- Optional Exchange application access policy to restrict Graph `Mail.Send` to the sender mailbox.
- Storage tables and queues.
- Function app settings.

Expected target tenant setup access:

- Azure subscription `Owner`, or `Contributor` plus the ability to create required role assignments.
- Microsoft Entra `Global Administrator` or `Privileged Role Administrator` for Graph application consent.

### Manual Identity Mode

Manual identity mode is for clients that want to pre-create privileged identity resources with their own administrative process.

In this mode, the client or MSP security team provides values such as:

```hcl
target_tenant_id        = "00000000-0000-0000-0000-000000000000"
graph_client_id         = "00000000-0000-0000-0000-000000000000"
graph_client_secret_ref = "https://vault-name.vault.azure.net/secrets/graph-client-secret"
license_group_id        = "00000000-0000-0000-0000-000000000000"
approval_email          = "approver@plutonix.onmicrosoft.com"
approval_sender_upn     = "onboarding@CholbingDevoutlook.onmicrosoft.com"
```

Terraform then deploys the Azure runtime and consumes the supplied IDs and secret references without owning the privileged Entra configuration.

This mode should be the preferred path for production clients that require change control over app registrations, admin consent, and licensing groups.

## Proposed Azure Components

| Component | Purpose |
| --- | --- |
| Microsoft Teams tab | Frontend onboarding form for client users |
| Azure Functions | HTTP endpoints and queue-triggered provisioning worker |
| Azure Storage Table | Request state, status, and audit metadata |
| Azure Storage Queue | Durable command handoff for user creation |
| Azure Key Vault | Secrets and certificate material if required |
| Application Insights | Logs, traces, and operational diagnostics |
| Microsoft Graph | User creation and group membership operations |
| Terraform | Repeatable per-client infrastructure deployment |

## Approval Email

The MVP uses Microsoft Graph `sendMail` for approval notifications.

The target tenant should provide a dedicated sender mailbox, for example:

```text
onboarding@CholbingDevoutlook.onmicrosoft.com
```

The Azure Functions app sends mail through:

```text
POST /users/{senderUserPrincipalName}/sendMail
```

Required configuration:

- `Approval__Provider=Graph`
- `Approval__SenderUserPrincipalName`
- `Approval__RecipientEmail`
- `Graph__TenantId`
- `Graph__ClientId`
- `Graph__ClientSecret` or a Key Vault-backed equivalent

Required Microsoft Graph application permission:

- `Mail.Send`

Because `Mail.Send` application permission can be broad, production deployments should restrict the app to the dedicated sender mailbox with an Exchange application access policy or equivalent control.

## Function Responsibilities

### SubmitOnboardingRequest

Accepts an onboarding form submission, validates the request, stores it with a pending status, and sends an approval email.

Expected responsibilities:

- Validate required fields.
- Validate the requester is allowed to submit.
- Normalize user details such as display name and UPN.
- Store the request with `PendingApproval` status.
- Generate a time-limited approval token.
- Send the approval email.

### ApproveOnboardingRequest

Receives an approval callback from the email link, verifies the token, marks the request approved, and queues the user creation command.

Expected responsibilities:

- Validate approval token.
- Prevent duplicate approval processing.
- Record approver details where available.
- Update status to `Approved`.
- Enqueue `CreateUser`.

### DenyOnboardingRequest

Receives a denial callback from the email link and closes the request without provisioning.

Expected responsibilities:

- Validate denial token.
- Prevent duplicate denial processing.
- Update status to `Denied`.
- Record denial timestamp and reason if supplied.

### CreateUser

Processes approved requests from the queue and provisions the Microsoft 365 user through Microsoft Graph.

Expected responsibilities:

- Load the approved request.
- Create the Entra ID user.
- Set account enabled state based on configuration.
- Optionally add the user to a configured licensing/security group.
- Update status to `Provisioned` or `ProvisioningFailed`.
- Store Graph error details needed for support without exposing secrets.

## Default MVP Fields

The first version should keep the onboarding form narrow:

- First name
- Last name
- Job title
- Department
- Manager email
- Start date
- Requested profile or license group
- Notes

## Security Model

The frontend must not call Microsoft Graph directly for provisioning. All privileged operations happen inside Azure Functions.

Recommended controls:

- Use tenant-local app registration permissions for Graph.
- Grant the minimum Graph application permissions required for the selected provisioning actions.
- Store secrets in Key Vault or use certificate-based auth where practical.
- Use managed identity for Azure resource access.
- Validate all submitted data server-side.
- Use one-time approval tokens with expiry.
- Log all state transitions.
- Keep approval and provisioning idempotent.
- Create users as disabled by default unless the deployment explicitly opts into enabled accounts.

The MVP approval links are token-based email callbacks. They record the approval method and timestamp, but they do not prove the named human approver unless interactive sign-in is added to the approval callback.

## Microsoft Graph Permissions

The MVP should require only the permissions needed to create users and optionally add them to a group.

Expected Graph operations:

- Send approval email from a dedicated sender mailbox.
- Create user.
- Add user to configured group.
- Optionally read existing users/groups for validation.

Expected application permissions:

- `Mail.Send` for approval email.
- `User.ReadWrite.All` for user creation.
- `GroupMember.ReadWrite.All` for group assignment.

Broad directory permissions should be avoided unless a chosen Graph operation requires them.

## Licensing Approach

The MVP should not directly assign license SKUs. Instead, approved users can be added to a configured Entra group. The client or MSP can attach group-based licensing policy to that group.

This keeps licensing policy outside the app and avoids making the starter solution responsible for tenant-specific SKU selection.

## Terraform Reuse Model

Terraform should support repeatable per-client deployment with variables such as:

```hcl
client_name                 = "contoso"
location                    = "australiaeast"
approval_email              = "service-desk@msp.example"
approval_sender_upn         = "onboarding@contoso.com"
default_user_domain         = "contoso.com"
target_tenant_domain        = "contoso.onmicrosoft.com"
target_tenant_id            = "00000000-0000-0000-0000-000000000000"
license_group_id            = "00000000-0000-0000-0000-000000000000"
allowed_submitter_group_id  = "00000000-0000-0000-0000-000000000000"
create_disabled_users       = true
provisioning_mode           = "manual-identity"
```

## Extension Points

The .NET implementation should keep integration boundaries replaceable:

```csharp
IApprovalNotifier
IOnboardingRequestStore
IUserProvisioningService
IApprovalTokenService
```

Default implementations:

- `EmailApprovalNotifier`
- `TableStorageOnboardingRequestStore`
- `GraphUserProvisioningService`
- `DataProtectionApprovalTokenService` or equivalent

## MVP Success Criteria

- A Teams user can submit an onboarding request.
- The request is stored with a pending state.
- The configured MSP approval mailbox receives an approval email.
- Approving the request queues user creation.
- The worker creates the user in the target tenant.
- The worker optionally adds the user to a configured group.
- The request status is updated through each stage.
- Terraform can deploy the required Azure infrastructure for a new client configuration.

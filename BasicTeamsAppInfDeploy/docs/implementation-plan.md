# Implementation Plan

## Phase 1: Project Shape

- Replace the starter Web API surface with a .NET Azure Functions app.
- Add solution structure for application services, infrastructure adapters, and shared models.
- Add local configuration samples for development.
- Add basic request validation and status models.

## Phase 2: Request Intake

- Implement `SubmitOnboardingRequest`.
- Persist onboarding requests to Azure Table Storage.
- Add server-side validation for required form fields.
- Add request status transitions.
- Add unit tests for validation and request creation.

## Phase 3: Email Approval

- Implement approval token generation and validation.
- Implement Microsoft Graph `sendMail` notification service.
- Configure dedicated sender mailbox UPN.
- Document `Mail.Send` admin consent and sender mailbox restriction expectations.
- Add `ApproveOnboardingRequest`.
- Add `DenyOnboardingRequest`.
- Ensure approval and denial are idempotent.
- Record approval method and approval/denial timestamp.
- Add tests for token expiry, duplicate approval, and denial.

## Phase 4: Provisioning Worker

- Add Azure Storage Queue command for approved requests.
- Implement `CreateUser` queue trigger.
- Add Microsoft Graph user creation service.
- Add optional group assignment for group-based licensing.
- Add failure status handling and retry-safe behavior.

## Phase 5: Teams Frontend

- Build a minimal Teams tab onboarding form.
- Configure the frontend to call the intake function.
- Add basic submit success and error states.
- Keep privileged operations out of the frontend.

## Phase 6: Terraform

- Add Terraform modules for:
  - Resource group
  - Storage account
  - Function app
  - Application Insights
  - Key Vault
  - App settings
  - Optional Entra app registration resources
- Add bootstrap app registration module for Graph application permissions.
- Add a sample client environment.
- Support bootstrap mode for lab or full-admin deployments.
- Support manual identity mode for pre-provisioned app registrations and groups.
- Document required tenant admin consent steps.
- Document which target tenant values must be supplied manually.

## Phase 7: Documentation and Hardening

- Add deployment guide.
- Add local development guide.
- Add security model notes.
- Add troubleshooting notes.
- Add architecture diagram.
- Add GitHub-ready README.

## Early Technical Decisions

- Use .NET for Azure Functions.
- Use Azure Storage Table for request state in the MVP.
- Use Azure Storage Queue for approved provisioning commands.
- Use email-based approval first.
- Use group-based licensing first.
- Deploy per client tenant.
- Keep MSP tenant access out of the MVP runtime path.
- Support both full bootstrap and manual privileged identity setup.
- Default to creating disabled users unless configured otherwise.

## Open Decisions

- Auth model for the Teams frontend.
- Whether bootstrap mode should create the Entra app registration through Terraform, a setup script, or both.
- Whether approval links should require interactive sign-in in addition to one-time token validation for named approver audit.
- Whether the first implementation targets Azure Functions isolated worker only.

param(
    [string] $GraphClientId,
    [switch] $AttemptAdminConsent
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    $knownAzureCliPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path -LiteralPath (Join-Path $knownAzureCliPath "az.cmd")) {
        $env:Path = "$knownAzureCliPath;$env:Path"
    }
}

if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    throw "Required command 'az' was not found on PATH."
}

if ([string]::IsNullOrWhiteSpace($GraphClientId)) {
    $tfvarsPath = Join-Path $PSScriptRoot "terraform.tfvars"
    if (-not (Test-Path -LiteralPath $tfvarsPath)) {
        throw "GraphClientId was not provided and terraform.tfvars was not found."
    }

    $graphClientIdMatch = Select-String `
        -LiteralPath $tfvarsPath `
        -Pattern '^\s*graph_client_id\s*=\s*"([^"]+)"' `
        -ErrorAction Stop

    if (-not $graphClientIdMatch) {
        throw "Could not read graph_client_id from terraform.tfvars."
    }

    $GraphClientId = $graphClientIdMatch.Matches[0].Groups[1].Value
}

$requiredPermissionValues = @(
    "Mail.Send",
    "User.ReadWrite.All"
)

$graphAppId = "00000003-0000-0000-c000-000000000000"
$graphServicePrincipal = az ad sp show --id $graphAppId --output json | ConvertFrom-Json
$requiredRoleIds = @{}
foreach ($permissionValue in $requiredPermissionValues) {
    $role = $graphServicePrincipal.appRoles | Where-Object { $_.value -eq $permissionValue }
    if (-not $role) {
        throw "Could not resolve Microsoft Graph application role '$permissionValue'."
    }

    $requiredRoleIds[$permissionValue] = $role.id
}

$application = az ad app show --id $GraphClientId --output json | ConvertFrom-Json
$servicePrincipal = az ad sp show --id $GraphClientId --output json | ConvertFrom-Json
$requestedPermissions = az ad app permission list --id $GraphClientId --output json | ConvertFrom-Json
$requestedRoleIds = @(
    $requestedPermissions `
        | Where-Object { $_.resourceAppId -eq $graphAppId } `
        | ForEach-Object { $_.resourceAccess } `
        | Where-Object { $_.type -eq "Role" } `
        | ForEach-Object { $_.id }
)

$assignments = az rest `
    --method get `
    --url "https://graph.microsoft.com/v1.0/servicePrincipals/$($servicePrincipal.id)/appRoleAssignments" `
    --output json `
    | ConvertFrom-Json

$grantedRoleIds = @(
    $assignments.value `
        | Where-Object { $_.resourceId -eq $graphServicePrincipal.id } `
        | ForEach-Object { $_.appRoleId }
)

$missingRequested = @()
$missingGranted = @()
foreach ($permissionValue in $requiredPermissionValues) {
    $roleId = $requiredRoleIds[$permissionValue]
    if ($requestedRoleIds -notcontains $roleId) {
        $missingRequested += $permissionValue
    }

    if ($grantedRoleIds -notcontains $roleId) {
        $missingGranted += $permissionValue
    }
}

Write-Host "Graph app registration: $($application.displayName) ($GraphClientId)"

if ($missingRequested.Count -gt 0) {
    throw "Missing requested Microsoft Graph application permissions: $($missingRequested -join ', ')."
}

Write-Host "Required Microsoft Graph application permissions are requested."

if ($missingGranted.Count -eq 0) {
    Write-Host "Required Microsoft Graph application permissions have admin consent."
    return
}

Write-Host "Missing admin consent for: $($missingGranted -join ', ')."

if (-not $AttemptAdminConsent) {
    throw "Admin consent is missing. Re-run with -AttemptAdminConsent using a Global Administrator or suitable privileged role."
}

az ad app permission admin-consent --id $GraphClientId --output none
Write-Host "Admin consent command completed. Re-run this script without -AttemptAdminConsent to verify grant state."

param(
    [string] $GroupDisplayName = "M365 Onboarding Teams App Users",
    [string] $GroupMailNickname = "m365-onboarding-teams-app-users",
    [string] $TargetUserPrincipalName = ""
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        return
    }

    $knownAzureCliPath = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin"
    if ($Name -eq "az" -and (Test-Path -LiteralPath (Join-Path $knownAzureCliPath "az.cmd"))) {
        $env:Path = "$knownAzureCliPath;$env:Path"
        return
    }

    throw "Required command '$Name' was not found on PATH."
}

function ConvertTo-ODataStringLiteral {
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    return $Value.Replace("'", "''")
}

Assert-Command -Name "az"

if ([string]::IsNullOrWhiteSpace($TargetUserPrincipalName)) {
    $TargetUserPrincipalName = Read-Host "Target user UPN to assign to the Teams app group"
}

if ([string]::IsNullOrWhiteSpace($TargetUserPrincipalName)) {
    throw "Target user UPN is required."
}

$escapedGroupDisplayName = ConvertTo-ODataStringLiteral -Value $GroupDisplayName
$groupFilter = "displayName eq '$escapedGroupDisplayName'"
$group = az ad group list --filter $groupFilter --query "[0]" --output json | ConvertFrom-Json

if ($null -eq $group) {
    Write-Host "Creating Entra group '$GroupDisplayName'."
    $group = az ad group create `
        --display-name $GroupDisplayName `
        --mail-nickname $GroupMailNickname `
        --description "Users assigned to the M365 Onboarding Teams app." `
        --output json | ConvertFrom-Json
}
else {
    Write-Host "Found existing Entra group '$GroupDisplayName'."
}

$user = az ad user show --id $TargetUserPrincipalName --output json | ConvertFrom-Json
if ($null -eq $user) {
    throw "Target user '$TargetUserPrincipalName' was not found."
}

$membership = az ad group member check `
    --group $group.id `
    --member-id $user.id `
    --output json | ConvertFrom-Json

if ($membership.value -eq $true) {
    Write-Host "User '$TargetUserPrincipalName' is already a member."
}
else {
    Write-Host "Adding user '$TargetUserPrincipalName' to '$GroupDisplayName'."
    az ad group member add --group $group.id --member-id $user.id | Out-Null
}

Write-Host ""
Write-Host "Teams app assignment group ready"
Write-Host "Group display name: $($group.displayName)"
Write-Host "Group object id:     $($group.id)"
Write-Host "Target user:         $TargetUserPrincipalName"

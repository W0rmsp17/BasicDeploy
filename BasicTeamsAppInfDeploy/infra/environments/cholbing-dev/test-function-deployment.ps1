param(
    [string] $TerraformPath = "..\..\..\..\terraform.exe",
    [int] $StartupWaitSeconds = 30
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

if (-not (Test-Path -LiteralPath $TerraformPath)) {
    throw "Terraform executable was not found at '$TerraformPath'."
}

$functionAppName = & $TerraformPath output -raw function_app_name
$resourceGroupName = & $TerraformPath output -raw resource_group_name
$functionAppHostname = & $TerraformPath output -raw function_app_default_hostname

if ([string]::IsNullOrWhiteSpace($functionAppName)) {
    throw "Terraform output 'function_app_name' was empty."
}

if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    throw "Terraform output 'resource_group_name' was empty."
}

if ([string]::IsNullOrWhiteSpace($functionAppHostname)) {
    throw "Terraform output 'function_app_default_hostname' was empty."
}

Write-Host "Restarting Function App '$functionAppName' before verification."
az functionapp restart `
    --resource-group $resourceGroupName `
    --name $functionAppName `
    --output none

if ($StartupWaitSeconds -gt 0) {
    Start-Sleep -Seconds $StartupWaitSeconds
}

$masterKey = az functionapp keys list `
    --resource-group $resourceGroupName `
    --name $functionAppName `
    --query "masterKey" `
    --output tsv

if ([string]::IsNullOrWhiteSpace($masterKey)) {
    throw "Could not retrieve Function App master key for host status verification."
}

$hostStatusUri = "https://$functionAppHostname/admin/host/status?code=$masterKey"
$hostStatusResponse = Invoke-WebRequest -Uri $hostStatusUri -SkipHttpErrorCheck
if ($hostStatusResponse.StatusCode -ne 200) {
    throw "Function host status endpoint returned HTTP $($hostStatusResponse.StatusCode)."
}

$hostStatus = $hostStatusResponse.Content | ConvertFrom-Json
if ($hostStatus.state -ne "Running") {
    $errors = if ($hostStatus.errors) { $hostStatus.errors -join " " } else { "No host errors were returned." }
    throw "Function host state is '$($hostStatus.state)'. $errors"
}

$functionNames = az functionapp function list `
    --resource-group $resourceGroupName `
    --name $functionAppName `
    --query "[].name" `
    --output tsv

$expectedFunctions = @(
    "ApproveOnboardingRequest",
    "CreateUser",
    "DenyOnboardingRequest",
    "SubmitOnboardingRequest"
)

$missingFunctions = @()
foreach ($expectedFunction in $expectedFunctions) {
    $expectedFullName = "$functionAppName/$expectedFunction"
    if ($functionNames -notcontains $expectedFullName) {
        $missingFunctions += $expectedFullName
    }
}

if ($missingFunctions.Count -gt 0) {
    throw "Function discovery is missing expected functions: $($missingFunctions -join ', ')."
}

Write-Host "Function host is running."
Write-Host "Discovered expected functions: $($expectedFunctions -join ', ')."

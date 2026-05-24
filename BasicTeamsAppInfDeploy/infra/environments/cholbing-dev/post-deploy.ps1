param(
    [string] $TerraformPath = "..\..\..\..\terraform.exe"
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

$approvalBaseUrl = "https://$functionAppHostname"

az functionapp config appsettings set `
    --resource-group $resourceGroupName `
    --name $functionAppName `
    --settings "Approval__BaseUrl=$approvalBaseUrl" `
    --output none

Write-Host "Updated Approval__BaseUrl for Function App '$functionAppName'."
Write-Host "Approval__BaseUrl=$approvalBaseUrl"

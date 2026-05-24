param(
    [string] $TerraformPath = "..\..\..\..\terraform.exe",
    [string] $TeamsAppPath = "..\..\..\teams-app",
    [string] $TeamsAppId = [guid]::NewGuid().ToString()
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $TerraformPath)) {
    throw "Terraform executable was not found at '$TerraformPath'."
}

if (-not (Test-Path -LiteralPath $TeamsAppPath)) {
    throw "Teams app path was not found at '$TeamsAppPath'."
}

$staticWebAppUrl = & $TerraformPath output -raw static_web_app_url
$staticWebAppHostname = & $TerraformPath output -raw static_web_app_default_hostname

if ([string]::IsNullOrWhiteSpace($staticWebAppUrl)) {
    throw "Terraform output 'static_web_app_url' was empty."
}

if ([string]::IsNullOrWhiteSpace($staticWebAppHostname)) {
    throw "Terraform output 'static_web_app_default_hostname' was empty."
}

$manifestDirectory = Join-Path (Resolve-Path -LiteralPath $TeamsAppPath) "manifest"
$templatePath = Join-Path $manifestDirectory "manifest.template.json"
$outputDirectory = Join-Path $manifestDirectory ".generated"
$outputPath = Join-Path $outputDirectory "manifest.json"

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Teams manifest template was not found at '$templatePath'."
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$manifest = Get-Content -LiteralPath $templatePath -Raw
$manifest = $manifest.Replace("{{TEAMS_APP_ID}}", $TeamsAppId)
$manifest = $manifest.Replace("{{FRONTEND_BASE_URL}}", $staticWebAppUrl.TrimEnd("/"))
$manifest = $manifest.Replace("{{FRONTEND_DOMAIN}}", $staticWebAppHostname)

Set-Content -LiteralPath $outputPath -Value $manifest -NoNewline

Write-Host "Wrote Teams manifest: $outputPath"
Write-Host "Teams app id: $TeamsAppId"
Write-Host "Frontend URL: $staticWebAppUrl"

param(
    [string] $TeamsAppPath = "..\..\..\teams-app"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $TeamsAppPath)) {
    throw "Teams app path was not found at '$TeamsAppPath'."
}

$teamsAppFullPath = Resolve-Path -LiteralPath $TeamsAppPath
$manifestDirectory = Join-Path $teamsAppFullPath "manifest"
$generatedDirectory = Join-Path $manifestDirectory ".generated"
$manifestPath = Join-Path $generatedDirectory "manifest.json"
$packagePath = Join-Path $generatedDirectory "m365-onboarding-teams-app.zip"
$colorIconPath = Join-Path $generatedDirectory "color.png"
$outlineIconPath = Join-Path $generatedDirectory "outline.png"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Generated manifest was not found at '$manifestPath'. Run new-teams-manifest.ps1 first."
}

Add-Type -AssemblyName System.Drawing

function New-ColorIcon {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $bitmap = [System.Drawing.Bitmap]::new(192, 192)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(39, 50, 74))

    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(243, 247, 250))
    $font = [System.Drawing.Font]::new("Segoe UI", 60, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString("365", $font, $brush, [System.Drawing.RectangleF]::new(0, 0, 192, 192), $format)

    $font.Dispose()
    $brush.Dispose()
    $format.Dispose()
    $graphics.Dispose()
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function New-OutlineIcon {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $bitmap = [System.Drawing.Bitmap]::new(32, 32)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 3)
    $graphics.DrawRectangle($pen, 6, 6, 20, 20)
    $graphics.DrawLine($pen, 11, 16, 15, 20)
    $graphics.DrawLine($pen, 15, 20, 22, 11)

    $pen.Dispose()
    $graphics.Dispose()
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

New-ColorIcon -Path $colorIconPath
New-OutlineIcon -Path $outlineIconPath

if (Test-Path -LiteralPath $packagePath) {
    Remove-Item -LiteralPath $packagePath -Force
}

$stagingDirectory = Join-Path $generatedDirectory "package"
if (Test-Path -LiteralPath $stagingDirectory) {
    Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
}

New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $stagingDirectory "manifest.json")
Copy-Item -LiteralPath $colorIconPath -Destination (Join-Path $stagingDirectory "color.png")
Copy-Item -LiteralPath $outlineIconPath -Destination (Join-Path $stagingDirectory "outline.png")

Compress-Archive -Path (Join-Path $stagingDirectory "*") -DestinationPath $packagePath -Force
Remove-Item -LiteralPath $stagingDirectory -Recurse -Force

Write-Host "Wrote Teams app package: $packagePath"

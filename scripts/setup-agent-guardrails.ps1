param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRepo,
    [string]$SourceDir = (Join-Path $PSScriptRoot "..\templates"),
    [ValidateSet("on", "off")]
    [string]$Guardrails = "on",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Copy-TemplateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        [switch]$ForceOverwrite
    )

    $destParent = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }

    if ((Test-Path $DestinationPath) -and (-not $ForceOverwrite)) {
        Write-Host "SKIP   $DestinationPath (exists, use -Force to overwrite)"
        return
    }

    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    Write-Host "COPY   $DestinationPath"
}

if (-not (Test-Path $TargetRepo)) {
    throw "Target repo path not found: $TargetRepo"
}

git -C $TargetRepo rev-parse --git-dir | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Target is not a Git repository: $TargetRepo"
}

if ($Guardrails -eq "off") {
    git -C $TargetRepo config --get core.hooksPath | Out-Null
    if ($LASTEXITCODE -eq 0) {
        git -C $TargetRepo config --unset core.hooksPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to unset core.hooksPath in target repo."
        }
        Write-Host "SET    git config --unset core.hooksPath"
    }
    else {
        Write-Host "INFO   Guardrails already disabled (core.hooksPath not set)."
    }

    Write-Host "DONE   Guardrails OFF for: $TargetRepo"
    return
}

if (-not (Test-Path $SourceDir)) {
    throw "Source templates dir not found: $SourceDir"
}

$manifestPath = Join-Path $SourceDir "install-manifest.txt"
if (-not (Test-Path $manifestPath)) {
    throw "Install manifest not found: $manifestPath"
}

foreach ($rawLine in Get-Content $manifestPath) {
    $line = $rawLine.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.StartsWith("#")) { continue }

    $lineWindows = $line -replace "/", "\"
    Copy-TemplateFile `
        -SourcePath (Join-Path $SourceDir $lineWindows) `
        -DestinationPath (Join-Path $TargetRepo $lineWindows) `
        -ForceOverwrite:$Force
}

git -C $TargetRepo config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    throw "Failed to set core.hooksPath in target repo."
}

Write-Host "SET    git config core.hooksPath .githooks"
Write-Host "DONE   Guardrails ON for: $TargetRepo"

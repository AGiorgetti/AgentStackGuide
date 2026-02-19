param(
    [Parameter(Mandatory = $false)]
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

function Get-ManifestLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    foreach ($rawLine in Get-Content $ManifestPath) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith("#")) { continue }
        $line
    }
}

function Resolve-DestinationPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRepoPath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ($RelativePath.StartsWith(".githooks/")) {
        $hookSuffix = $RelativePath.Substring(".githooks/".Length)
        return (Join-Path $TargetRepoPath (Join-Path ".git\hooks" $hookSuffix))
    }

    $lineWindows = $RelativePath -replace "/", "\"
    return (Join-Path $TargetRepoPath $lineWindows)
}
function Install-Hook {
    param(
        [Parameter(Mandatory = $true)] [string]$SourcePath,
        [Parameter(Mandatory = $true)] [string]$DestinationHookPath,
        [switch]$ForceOverwrite
    )

    $hookName = Split-Path -Leaf $DestinationHookPath
    $hooksDir = Split-Path -Parent $DestinationHookPath
    $agentHook = Join-Path $hooksDir ("agent-guardrails-" + $hookName)
    $origHook = "$DestinationHookPath.orig"

    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }

    if (Test-Path $DestinationHookPath) {
        $destContent = Get-Content -Raw -Path $DestinationHookPath
        $srcContent = Get-Content -Raw -Path $SourcePath
        if ($destContent -eq $srcContent) {
            Copy-TemplateFile -SourcePath $SourcePath -DestinationPath $agentHook -ForceOverwrite:$ForceOverwrite
            return
        }

        if (-not (Test-Path $origHook)) {
            Move-Item -Path $DestinationHookPath -Destination $origHook -Force
            Write-Host "BACKUP $origHook"
        }
        else {
            Write-Host "INFO   backup exists: $origHook"
        }
    }

    Copy-TemplateFile -SourcePath $SourcePath -DestinationPath $agentHook -ForceOverwrite:$ForceOverwrite

    $dispatcher = @"
#!/usr/bin/env bash
set -euo pipefail
HOOKDIR="`$(dirname "`$0")`"
"`$HOOKDIR/agent-guardrails-$hookName" "`$@" || exit `$?
if [ -x "`$HOOKDIR/$hookName.orig" ]; then
  "`$HOOKDIR/$hookName.orig" "`$@" || exit `$?
fi
exit 0
"@
    # Normalize line endings to LF and write without BOM
    $dispatcherNormalized = $dispatcher -replace "`r?`n", "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($DestinationHookPath, $dispatcherNormalized, $utf8NoBom)
    Write-Host "DISPATCH $DestinationHookPath"
}

function Uninstall-Hook {
    param(
        [Parameter(Mandatory = $true)] [string]$SourcePath,
        [Parameter(Mandatory = $true)] [string]$DestinationHookPath
    )

    $hookName = Split-Path -Leaf $DestinationHookPath
    $hooksDir = Split-Path -Parent $DestinationHookPath
    $agentHook = Join-Path $hooksDir ("agent-guardrails-" + $hookName)
    $origHook = "$DestinationHookPath.orig"

    if (-not (Test-Path $DestinationHookPath)) { return }

    $destContent = Get-Content -Raw -Path $DestinationHookPath
    if ($destContent -match "agent-guardrails-$hookName") {
        if (Test-Path $origHook) {
            Move-Item -Path $origHook -Destination $DestinationHookPath -Force
            Write-Host "RESTORE $DestinationHookPath"
        }
        else {
            Remove-Item -Path $DestinationHookPath -Force
            Write-Host "REMOVE $DestinationHookPath"
        }
    }
    else {
        $srcContent = Get-Content -Raw -Path $SourcePath
        if ($srcContent -eq $destContent) {
            Remove-Item -Path $DestinationHookPath -Force
            Write-Host "REMOVE $DestinationHookPath"
        }
        else {
            Write-Host "SKIP   $DestinationHookPath (exists, not a guardrails hook)"
        }
    }

    if ((Test-Path $agentHook) -and (Test-Path $SourcePath)) {
        $agContent = Get-Content -Raw -Path $agentHook
        $sContent = Get-Content -Raw -Path $SourcePath
        if ($agContent -eq $sContent) {
            Remove-Item -Path $agentHook -Force
            Write-Host "REMOVE $agentHook"
        }
    }
}
function Prompt-GuardrailsInput {
    Write-Host "Interactive mode."

    $guardrailsInput = Read-Host "Enable guardrails? (y/n)"
    if ($guardrailsInput -match "^[Yy]") {
        $guardrailsValue = "on"
    }
    elseif ($guardrailsInput -match "^[Nn]") {
        $guardrailsValue = "off"
    }
    else {
        Write-Host "CANCEL User cancelled guardrails setup."
        exit 0
    }

    $repoInput = Read-Host "Target Git repository path"
    if ([string]::IsNullOrWhiteSpace($repoInput)) {
        Write-Host "CANCEL No repo selected."
        exit 0
    }

    $selection = @{
        Guardrails = $guardrailsValue
        TargetRepo = $repoInput
        SourceDir = $SourceDir
        Force = $false
    }

    if ($guardrailsValue -eq "on") {
        $sourceInput = Read-Host "Templates folder [$SourceDir]"
        if (-not [string]::IsNullOrWhiteSpace($sourceInput)) {
            $selection.SourceDir = $sourceInput
        }

        $forceInput = Read-Host "Overwrite existing files? (y/n)"
        if ($forceInput -match "^[Yy]") {
            $selection.Force = $true
        }
    }

    return $selection
}

if (-not $TargetRepo) {
    $promptSelection = Prompt-GuardrailsInput
    $TargetRepo = $promptSelection.TargetRepo
    $Guardrails = $promptSelection.Guardrails
    $SourceDir = $promptSelection.SourceDir
    $Force = $promptSelection.Force
}

if (-not (Test-Path $TargetRepo)) {
    throw "Target repo path not found: $TargetRepo"
}

git -C $TargetRepo rev-parse --git-dir | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Target is not a Git repository: $TargetRepo"
}

if ($Guardrails -eq "off") {
    if (-not (Test-Path $SourceDir)) {
        Write-Host "INFO   Source templates dir not found; skipping hook removal."
        Write-Host "DONE   Guardrails OFF for: $TargetRepo"
        return
    }

    $manifestPath = Join-Path $SourceDir "install-manifest.txt"
    if (-not (Test-Path $manifestPath)) {
        Write-Host "INFO   Install manifest not found; skipping hook removal."
        Write-Host "DONE   Guardrails OFF for: $TargetRepo"
        return
    }

    foreach ($line in Get-ManifestLines -ManifestPath $manifestPath) {
        if (-not $line.StartsWith(".githooks/")) { continue }
        $sourcePath = Join-Path $SourceDir ($line -replace "/", "\")
        $hookName = $line.Substring(".githooks/".Length)
        $destinationPath = Join-Path $TargetRepo ".git\hooks\$hookName"
        Uninstall-Hook -SourcePath $sourcePath -DestinationHookPath $destinationPath
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

foreach ($line in Get-ManifestLines -ManifestPath $manifestPath) {
    if ($line.StartsWith(".githooks/")) {
        $src = Join-Path $SourceDir ($line -replace "/", "\")
        $hookName = $line.Substring(".githooks/".Length)
        $dest = Join-Path $TargetRepo ".git\hooks\$hookName"
        Install-Hook -SourcePath $src -DestinationHookPath $dest -ForceOverwrite:$Force
    }
    else {
        $lineWindows = $line -replace "/", "\"
        Copy-TemplateFile `
            -SourcePath (Join-Path $SourceDir $lineWindows) `
            -DestinationPath (Resolve-DestinationPath -TargetRepoPath $TargetRepo -RelativePath $line) `
            -ForceOverwrite:$Force
    }
}
Write-Host "DONE   Guardrails ON for: $TargetRepo"

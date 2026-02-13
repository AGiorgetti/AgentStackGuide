param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRepo,
    [string]$SourceDir = (Join-Path $PSScriptRoot "..\templates"),
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

if (-not (Test-Path $SourceDir)) {
    throw "Source templates dir not found: $SourceDir"
}

if (-not (Test-Path $TargetRepo)) {
    throw "Target repo path not found: $TargetRepo"
}

git -C $TargetRepo rev-parse --git-dir | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Target is not a Git repository: $TargetRepo"
}

Copy-TemplateFile -SourcePath (Join-Path $SourceDir "AGENT_EXECUTION_CONTRACT.md") -DestinationPath (Join-Path $TargetRepo "AGENT_EXECUTION_CONTRACT.md") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir "AGENTS.md") -DestinationPath (Join-Path $TargetRepo "AGENTS.md") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir "CLAUDE.md") -DestinationPath (Join-Path $TargetRepo "CLAUDE.md") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir "COPILOT.md") -DestinationPath (Join-Path $TargetRepo "COPILOT.md") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir "AGENT_KICKOFF_PROMPT.md") -DestinationPath (Join-Path $TargetRepo "AGENT_KICKOFF_PROMPT.md") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir ".github\copilot-instructions.md") -DestinationPath (Join-Path $TargetRepo ".github\copilot-instructions.md") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir ".githooks\pre-commit") -DestinationPath (Join-Path $TargetRepo ".githooks\pre-commit") -ForceOverwrite:$Force
Copy-TemplateFile -SourcePath (Join-Path $SourceDir ".githooks\pre-push") -DestinationPath (Join-Path $TargetRepo ".githooks\pre-push") -ForceOverwrite:$Force

git -C $TargetRepo config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    throw "Failed to set core.hooksPath in target repo."
}

Write-Host "SET    git config core.hooksPath .githooks"
Write-Host "DONE   Guardrail bootstrap complete for: $TargetRepo"

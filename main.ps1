# Main Entry Point
# Orchestrates deployment and launches the remote manager.

$ErrorActionPreference = "Stop"
$ScriptDir = "scripts"

Write-Host "=== Universal Game Server Manager ===" -ForegroundColor Cyan

# 1. Deploy Phase
Write-Host "[Phase 1] Deployment & Setup" -ForegroundColor Green
& "$ScriptDir\deploy.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed. Aborting." -ForegroundColor Red
    exit 1
}

# 2. Execution Phase
Write-Host "[Phase 2] Launching Remote Manager" -ForegroundColor Green
Write-Host "Handing over control to the server..." -ForegroundColor Gray

# Command to run on the server
$RemoteCmd = "bash -c 'cd ~/server_manager && ./scripts/manager.sh'"

& "$ScriptDir\connect.ps1" -RemoteCommand $RemoteCmd

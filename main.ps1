# Main Entry Point
# Orchestrates deployment, management, and save syncing.

$ErrorActionPreference = "Stop"
$ScriptDir = "scripts"

function Show-Menu {
    Clear-Host
    Write-Host "=== Universal Game Server Manager ===" -ForegroundColor Cyan
    Write-Host "1. Deploy / Update Server (Install Scripts)"
    Write-Host "2. Connect to Remote Manager"
    Write-Host "3. Sync Saves (Upload/Download)"
    Write-Host "4. Sync Configurations (Upload/Download)"
    Write-Host "5. Setup Cloud Auth (Inject Token)"
    Write-Host "Q. Quit"
    Write-Host "-------------------------------------"
}

while ($true) {
    Show-Menu
    $Choice = Read-Host "Select an option"
    
    switch ($Choice) {
        "1" {
            Write-Host "[Phase 1] Deployment & Setup" -ForegroundColor Green
            & "$ScriptDir\deploy.ps1"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Deployment failed." -ForegroundColor Red
            } else {
                Write-Host "Deployment successful." -ForegroundColor Green
            }
            Pause
        }
        "2" {
            Write-Host "[Phase 2] Launching Remote Manager" -ForegroundColor Green
            $RemoteCmd = "bash -c 'cd ~/server_manager && ./scripts/manager.sh'"
            & "$ScriptDir\connect.ps1" -RemoteCommand $RemoteCmd
        }
        "3" {
            & "$ScriptDir\sync_saves.ps1"
            Pause
        }
        "4" {
            & "$ScriptDir\sync_configs.ps1"
            Pause
        }
        "5" {
            & "$ScriptDir\setup_cloud.ps1"
            Pause
        }
        "Q" { exit }
        "q" { exit }
        Default { Write-Host "Invalid option." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
    }
}

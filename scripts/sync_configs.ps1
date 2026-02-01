# Configuration Synchronization Script
# Handles uploading and downloading instance settings (settings.sh, serverconfig.txt, etc.)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ProjectRoot "env\.env"

# --- Load Configuration ---
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: Configuration file '$EnvFile' not found." -ForegroundColor Red
    exit 1
}

$Config = @{}
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)=(.*)$") {
        $Config[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$ServerIP = $Config["SERVER_IP"]
$ServerUser = if ($Config["SERVER_USER"]) { $Config["SERVER_USER"] } else { "root" }
$KeyPath = if ($Config["SSH_KEY_PATH"]) { Join-Path $ProjectRoot $Config["SSH_KEY_PATH"] } else { "" }

# --- Setup Connection Mode ---
$UsePutty = $false
if ($KeyPath -and $KeyPath.EndsWith(".ppk")) {
    $UsePutty = $true
}

function Get-RemoteInstances {
    $Cmd = "ls -1 ~/server_manager/configs/ 2>/dev/null"
    if ($UsePutty) {
        return plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd"
    } else {
        $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
        if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
        return ssh @SSHArgs
    }
}

Write-Host "=== Configuration Sync ===" -ForegroundColor Cyan
Write-Host "Fetching remote instances..." -ForegroundColor Gray

$RemoteInstances = Get-RemoteInstances -split "`n" | Where-Object { $_ -match "\S" }
$LocalConfigDir = Join-Path $ProjectRoot "configs"
$LocalInstances = if (Test-Path $LocalConfigDir) { Get-ChildItem -Path $LocalConfigDir -Directory | Select-Object -ExpandProperty Name } else { @() }

# Combine and unique
$AllInstances = ($RemoteInstances + $LocalInstances) | Select-Object -Unique | Sort-Object

if ($AllInstances.Count -eq 0) {
    Write-Host "No instances found locally or remotely." -ForegroundColor Yellow
    exit
}

for ($i=0; $i -lt $AllInstances.Count; $i++) {
    $Status = ""
    if ($RemoteInstances -contains $AllInstances[$i] -and $LocalInstances -contains $AllInstances[$i]) { $Status = "[Both]" }
    elseif ($RemoteInstances -contains $AllInstances[$i]) { $Status = "[Remote Only]" }
    else { $Status = "[Local Only]" }
    Write-Host "$($i+1)) $($AllInstances[$i]) $Status"
}

$Selection = Read-Host "Select an instance (1-$($AllInstances.Count))"
if ($Selection -match "^\d+$" -and $Selection -ge 1 -and $Selection -le $AllInstances.Count) {
    $SelectedInstance = $AllInstances[$Selection-1]
} else {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit
}

$LocalPath = Join-Path $LocalConfigDir $SelectedInstance
$RemotePath = "~/server_manager/configs/$SelectedInstance"

Write-Host ""
Write-Host "Action for '$SelectedInstance':"
Write-Host "1) Push Local -> Remote (Upload files, skip saves)"
Write-Host "2) Pull Remote -> Local (Download files, skip saves)"
$Action = Read-Host "Select action"

if ($Action -eq "1") {
    if (-not (Test-Path $LocalPath)) { Write-Host "Error: Local path does not exist." -ForegroundColor Red; exit }
    Write-Host "Pushing configurations to server..." -ForegroundColor Cyan
    
    # Create clean temp for upload
    $Tmp = Join-Path $ProjectRoot "sync_config_tmp"
    if (Test-Path $Tmp) { Remove-Item -Recurse -Force $Tmp }
    New-Item -ItemType Directory -Path $Tmp | Out-Null
    
    Get-ChildItem -Path $LocalPath | Where-Object { $_.Name -ne "saves" -and $_.Extension -ne ".zip" -and $_.Extension -ne ".wld" } | ForEach-Object {
        Copy-Item -Recurse -Path $_.FullName -Destination $Tmp
    }

    if ($UsePutty) {
        # Ensure remote dir
        plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "mkdir -p $RemotePath"
        pscp.exe -r -i "$KeyPath" "$Tmp\*" "$ServerUser@$ServerIP`:$RemotePath/"
    } else {
        ssh -i "$KeyPath" "$ServerUser@$ServerIP" "mkdir -p $RemotePath"
        $SCPArgs = @("-r", "$Tmp/*", "$ServerUser@$ServerIP`:$RemotePath/")
        if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
        scp @SCPArgs
    }
    Remove-Item -Recurse -Force $Tmp
    Write-Host "Push complete." -ForegroundColor Green

} elseif ($Action -eq "2") {
    if (-not (Test-Path $LocalPath)) { New-Item -ItemType Directory -Path $LocalPath | Out-Null }
    Write-Host "Pulling configurations from server..." -ForegroundColor Cyan
    
    # Get file list (files only, skip directories like 'saves')
    $Cmd = "ls -p $RemotePath | grep -v /"
    if ($UsePutty) { $Files = plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd" }
    else { 
        $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
        if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
        $Files = ssh @SSHArgs
    }

    foreach ($f in ($Files -split "`n" | Where-Object { $_ -match "\S" })) {
        $f = $f.Trim()
        Write-Host "  Syncing $f..."
        if ($UsePutty) { pscp.exe -i "$KeyPath" "$ServerUser@$ServerIP`:$RemotePath/$f" "$LocalPath" }
        else { 
            $SCPArgs = @("$ServerUser@$ServerIP`:$RemotePath/$f", "$LocalPath")
            if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
            scp @SCPArgs 
        }
    }
    Write-Host "Pull complete." -ForegroundColor Green
}

# Save Synchronization Script
# Handles uploading and downloading game saves.

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

# --- Helper Functions ---

function Get-RemoteInstances {
    # Lists directories in ~/server_manager/configs/
    $Cmd = "ls -1 ~/server_manager/configs/"
    if ($UsePutty) {
        $Output = plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd"
    } else {
        $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
        if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
        $Output = ssh @SSHArgs
    }
    return $Output
}

function Get-GameMetadata {
    param($GameName)
    $IniFile = Join-Path $ProjectRoot "games\$GameName\game.ini"
    if (Test-Path $IniFile) {
        $Meta = @{}
        Get-Content $IniFile | ForEach-Object {
            if ($_ -match "^\s*([^#=]+)=(.*)$") {
                $Meta[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
        return $Meta
    }
    return $null
}

# --- Setup Connection Mode ---
$UsePutty = $false
if ($KeyPath -and $KeyPath.EndsWith(".ppk")) {
    $UsePutty = $true
}

Write-Host "=== Save Manager ===" -ForegroundColor Cyan
Write-Host "Fetching remote instances..." -ForegroundColor Gray

$Instances = Get-RemoteInstances
if (-not $Instances) {
    Write-Host "No remote server instances found." -ForegroundColor Yellow
    exit
}

# --- Select Instance ---
Write-Host "Available Remote Instances:"
$InstanceList = $Instances -split "`n" | Where-Object { $_ -match "\S" }
for ($i=0; $i -lt $InstanceList.Count; $i++) {
    Write-Host "$($i+1)) $($InstanceList[$i])"
}

$Selection = Read-Host "Select an instance (1-$($InstanceList.Count))"
if ($Selection -match "^\d+$" -and $Selection -ge 1 -and $Selection -le $InstanceList.Count) {
    $SelectedInstance = $InstanceList[$Selection-1]
} else {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit
}

# --- Determine Game Type ---
# We need to know which game this instance is to know the format.
# We'll cat the settings.sh remotely.
$Cmd = "cat ~/server_manager/configs/$SelectedInstance/settings.sh | grep 'GAME='"
if ($UsePutty) {
    $RawGame = plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd"
} else {
    $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
    if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
    $RawGame = ssh @SSHArgs
}

if ($RawGame -match "GAME=`"(.*)`"") {
    $GameType = $matches[1]
} else {
    $GameType = "unknown"
}

$Meta = Get-GameMetadata -GameName $GameType
$SaveFormat = if ($Meta) { $Meta["save_format"] } else { "file" } # default file

Write-Host "Selected: $SelectedInstance ($GameType)" -ForegroundColor Green
Write-Host "Save Format: $SaveFormat" -ForegroundColor Gray

# --- Action Menu ---
Write-Host ""
Write-Host "1) Upload Save (Local -> Remote)"
Write-Host "2) Download Save (Remote -> Local)"
$Action = Read-Host "Select action"

$RemoteBasePath = "~/server_manager/configs/$SelectedInstance/saves"
$LocalBasePath = Join-Path $ProjectRoot "saves\$GameType"

# Ensure local folder exists
New-Item -ItemType Directory -Force -Path $LocalBasePath | Out-Null

if ($Action -eq "1") {
    # --- UPLOAD ---
    Write-Host "Local saves in $LocalBasePath:"
    $LocalFiles = Get-ChildItem -Path $LocalBasePath
    for ($i=0; $i -lt $LocalFiles.Count; $i++) {
        Write-Host "$($i+1)) $($LocalFiles[$i].Name)"
    }
    
    $FileSel = Read-Host "Select file/folder to upload (1-$($LocalFiles.Count))"
    if ($FileSel -match "^\d+$" -and $FileSel -ge 1 -and $FileSel -le $LocalFiles.Count) {
        $SourceItem = $LocalFiles[$FileSel-1]
        
        Write-Host "Uploading $($SourceItem.Name)..." -ForegroundColor Cyan
        
        if ($UsePutty) {
            pscp.exe -r -i "$KeyPath" "$($SourceItem.FullName)" "$ServerUser@$ServerIP`:$RemoteBasePath/"
        } else {
            $SCPArgs = @("-r", "$($SourceItem.FullName)", "$ServerUser@$ServerIP`:$RemoteBasePath/")
            if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
            scp @SCPArgs
        }
        Write-Host "Upload complete." -ForegroundColor Green
    }

} elseif ($Action -eq "2") {
    # --- DOWNLOAD ---
    # List remote saves
    Write-Host "Fetching remote save list..."
    $Cmd = "ls -1 $RemoteBasePath"
    if ($UsePutty) {
        $RemoteFiles = plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd"
    } else {
        $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
        if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
        $RemoteFiles = ssh @SSHArgs
    }
    
    $RFileList = $RemoteFiles -split "`n" | Where-Object { $_ -match "\S" }
    for ($i=0; $i -lt $RFileList.Count; $i++) {
        Write-Host "$($i+1)) $($RFileList[$i])"
    }
    
    $FileSel = Read-Host "Select remote save to download (1-$($RFileList.Count))"
    if ($FileSel -match "^\d+$" -and $FileSel -ge 1 -and $FileSel -le $RFileList.Count) {
        $TargetName = $RFileList[$FileSel-1]
        
        Write-Host "Downloading $TargetName to $LocalBasePath..." -ForegroundColor Cyan
        
        if ($UsePutty) {
            pscp.exe -r -i "$KeyPath" "$ServerUser@$ServerIP`:$RemoteBasePath/$TargetName" "$LocalBasePath"
        } else {
            $SCPArgs = @("-r", "$ServerUser@$ServerIP`:$RemoteBasePath/$TargetName", "$LocalBasePath")
            if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
            scp @SCPArgs
        }
        Write-Host "Download complete." -ForegroundColor Green
    }
}

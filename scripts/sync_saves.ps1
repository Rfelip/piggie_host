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

# --- Determine Game Type and Active Save ---
# We need to know which game this instance is and what the active save is.
$Cmd = "cat ~/server_manager/configs/$SelectedInstance/settings.sh"
if ($UsePutty) {
    $SettingsContent = plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd"
} else {
    $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
    if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
    $SettingsContent = ssh @SSHArgs
}

$GameType = "unknown"
$ActiveSavePath = ""
$SaveName = ""

$SettingsContent -split "`n" | ForEach-Object {
    if ($_ -match "^GAME=`"(.*)`"") { $GameType = $matches[1] }
    if ($_ -match "^SAVE_FILE=`"(.*)`"") { $ActiveSavePath = $matches[1] }
    if ($_ -match "^SAVE_NAME=`"(.*)`"") { $SaveName = $matches[1] }
    if ($_ -match "^SETTINGS_FILE=`"(.*)`"") { $CurrentSettingsFile = $matches[1] }
}

# Auto-fix SETTINGS_FILE if it's wrong for Terraria
if ($GameType -eq "terraria" -and $CurrentSettingsFile -eq "server-settings.json") {
    Write-Host "  Detected incorrect SETTINGS_FILE for Terraria. Fixing..." -ForegroundColor Yellow
    # Using a single-quoted string in PowerShell to avoid escape character issues
    $FixCmd = 'sed -i "s/SETTINGS_FILE=.*/SETTINGS_FILE=\"serverconfig.txt\"/" ~/server_manager/configs/' + $SelectedInstance + '/settings.sh'
    if ($UsePutty) { 
        plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" $FixCmd 
    }
    else { 
        $SSHArgs = @("-i", "$KeyPath", "$ServerUser@$ServerIP", $FixCmd)
        ssh @SSHArgs
    }
    $CurrentSettingsFile = "serverconfig.txt"
}

$Meta = Get-GameMetadata -GameName $GameType
$SaveFormat = if ($Meta) { $Meta["save_format"] } else { "file" } # default file

Write-Host "Selected: $SelectedInstance ($GameType)" -ForegroundColor Green
if ($GameType -eq "terraria") {
    $ResolvedSave = if ($ActiveSavePath) { $ActiveSavePath } else { $SaveName }
    if (-not $ResolvedSave) { $ResolvedSave = $SelectedInstance }
    
    if ($ResolvedSave -match "[/\\\\\\]") {
        $ActiveSavePath = $ResolvedSave
    } else {
        $ActiveSavePath = "~/.local/share/Terraria/Worlds/$ResolvedSave.wld"
    }
    Write-Host "Active Save: $ResolvedSave" -ForegroundColor Gray
} else {
    Write-Host "Active Save: $ActiveSavePath" -ForegroundColor Gray
}

# --- Action Menu ---
Write-Host ""
Write-Host "1) Upload Save (Local -> Remote)"
Write-Host "2) Download Save (Remote -> Local)"
Write-Host "3) Quick Backup (Download Active Save with Timestamp)"
$Action = Read-Host "Select action"

if ($GameType -eq "terraria") {
    $RemoteBasePath = "~/.local/share/Terraria/Worlds"
} else {
    $RemoteBasePath = "~/server_manager/configs/$SelectedInstance/saves"
}
$LocalBasePath = Join-Path $ProjectRoot "saves\$GameType"

# Ensure local folder exists
New-Item -ItemType Directory -Force -Path $LocalBasePath | Out-Null

if ($Action -eq "1") {
    # ... (Upload logic remains same) ...
    Write-Host "Local saves in ${LocalBasePath}:"
    $LocalFiles = Get-ChildItem -Path $LocalBasePath
    for ($i=0; $i -lt $LocalFiles.Count; $i++) {
        Write-Host "$($i+1)) $($LocalFiles[$i].Name)"
    }
    
    $FileSel = Read-Host "Select file/folder to upload (1-$($LocalFiles.Count))"
    if ($FileSel -match "^\d+$" -and $FileSel -ge 1 -and $FileSel -le $LocalFiles.Count) {
        $SourceItem = $LocalFiles[$FileSel-1]
        
        Write-Host "Uploading $($SourceItem.Name)..." -ForegroundColor Cyan
        
        # If active save is in a subdirectory (e.g. saves/file.zip), we need to upload to the right place.
        # But here we are uploading TO 'saves' folder.
        
        if ($UsePutty) {
            pscp.exe -r -i "$KeyPath" "$($SourceItem.FullName)" "$ServerUser@$ServerIP`:${RemoteBasePath}/"
        } else {
            $SCPArgs = @("-r", "$($SourceItem.FullName)", "$ServerUser@$ServerIP`:${RemoteBasePath}/")
            if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
            scp @SCPArgs
        }
        Write-Host "Upload complete." -ForegroundColor Green
    }

} elseif ($Action -eq "2") {
    # ... (Download logic remains same) ...
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
        
        Write-Host "Downloading $TargetName to ${LocalBasePath}..." -ForegroundColor Cyan
        
        if ($UsePutty) {
            pscp.exe -r -i "$KeyPath" "$ServerUser@$ServerIP`:${RemoteBasePath}/$TargetName" "$LocalBasePath"
        } else {
            $SCPArgs = @("-r", "$ServerUser@$ServerIP`:${RemoteBasePath}/$TargetName", "$LocalBasePath")
            if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
            scp @SCPArgs
        }
        Write-Host "Download complete." -ForegroundColor Green
    }

} elseif ($Action -eq "3") {
    # --- QUICK BACKUP ---
    if (-not $ActiveSavePath) {
        Write-Host "Error: Could not determine active save file from settings.sh" -ForegroundColor Red
        exit
    }
    
    # ActiveSavePath is usually relative to instance dir (e.g., "saves/myworld.zip")
    # We need to construct the full remote path.
    if ($ActiveSavePath -match "^(~|/)") {
        $RemoteSaveFull = $ActiveSavePath
    } else {
        $RemoteSaveFull = "~/server_manager/configs/$SelectedInstance/$ActiveSavePath"
    }
    
    # Construct Local Name
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BaseName = Split-Path $ActiveSavePath -Leaf
    
    # Handle extensions if present
    if ($BaseName -match "^(.+)(\.[^.]+)$") {
        $NameOnly = $matches[1]
        $Ext = $matches[2]
        $LocalName = "${NameOnly}_${Timestamp}${Ext}"
    } else {
        $LocalName = "${BaseName}_${Timestamp}"
    }
    
    $TargetLocalPath = Join-Path $LocalBasePath $LocalName
    
    Write-Host "Backing up active save: $ActiveSavePath" -ForegroundColor Cyan
    Write-Host "Source: $RemoteSaveFull" -ForegroundColor Gray
    Write-Host "Destination: ${TargetLocalPath}" -ForegroundColor Gray
    
    if ($UsePutty) {
        pscp.exe -r -i "$KeyPath" "$ServerUser@$ServerIP`:${RemoteSaveFull}" "$TargetLocalPath"
    } else {
        $SCPArgs = @("-r", "$ServerUser@$ServerIP`:${RemoteSaveFull}", "$TargetLocalPath")
        if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
        scp @SCPArgs
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Backup successful!" -ForegroundColor Green
    } else {
        Write-Host "Backup failed. Check if the active save file actually exists on the server." -ForegroundColor Red
    }
}

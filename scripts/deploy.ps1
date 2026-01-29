# Deploy and Setup Script
# Orchestrates the upload and execution of the server manager on the remote host.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ProjectRoot "env\.env"

# 1. Load Configuration
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

if (-not $ServerIP) {
    Write-Host "Error: SERVER_IP not set in .env" -ForegroundColor Red
    exit 1
}

Write-Host "Deploying to $ServerUser@$ServerIP..." -ForegroundColor Cyan

# 2. Determine Transfer Method (SCP vs PSCP)
$UsePutty = $false
if ($KeyPath -and $KeyPath.EndsWith(".ppk")) {
    $UsePutty = $true
    if (-not (Get-Command pscp.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Error: .ppk key detected but 'pscp.exe' not found in PATH." -ForegroundColor Red
        Write-Host "Please install PuTTY tools or convert key to OpenSSH format."
        exit 1
    }
    if (-not (Get-Command plink.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Error: 'plink.exe' not found in PATH." -ForegroundColor Red
        exit 1
    }
}

# 3. Prepare Remote Directory
$RemoteDir = "~/server_manager"
Write-Host "Creating remote directory: $RemoteDir" -ForegroundColor Gray

$MkdirCmd = "mkdir -p $RemoteDir/scripts/setup $RemoteDir/games $RemoteDir/configs"
if ($UsePutty) {
    plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$MkdirCmd"
} else {
    $SSHArgs = @("$ServerUser@$ServerIP", "$MkdirCmd")
    if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
    ssh @SSHArgs
}

# 4. Upload Scripts (Smart Deployment)
Write-Host "Syncing code (scripts/games)..." -ForegroundColor Gray

# Create a clean staging area for code only
$TmpCode = Join-Path $ProjectRoot "deploy_code_tmp"
if (Test-Path $TmpCode) { Remove-Item -Recurse -Force $TmpCode }
New-Item -ItemType Directory -Path $TmpCode | Out-Null
Copy-Item -Recurse -Path (Join-Path $ProjectRoot "scripts") -Destination $TmpCode
Copy-Item -Recurse -Path (Join-Path $ProjectRoot "games") -Destination $TmpCode

# Upload Code (Overwrite)
if ($UsePutty) {
    Get-ChildItem -Path $TmpCode | ForEach-Object {
        pscp.exe -r -i "$KeyPath" "$($_.FullName)" "$ServerUser@$ServerIP`:$RemoteDir/"
    }
} else {
    $Files = Get-ChildItem -Path $TmpCode | Select-Object -ExpandProperty FullName
    $SCPArgs = @("-r") + $Files + @("$ServerUser@$ServerIP`:$RemoteDir/")
    if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
    scp @SCPArgs
}
Remove-Item -Recurse -Force $TmpCode

# Smart Config Upload
Write-Host "Syncing configurations..." -ForegroundColor Gray

# 1. Get list of remote instances
$Cmd = "ls -1 $RemoteDir/configs 2>/dev/null"
if ($UsePutty) {
    $RemoteOutput = plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$Cmd"
} else {
    $SSHArgs = @("$ServerUser@$ServerIP", "$Cmd")
    if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
    $RemoteOutput = ssh @SSHArgs
}
$RemoteInstances = $RemoteOutput -split "`n" | Where-Object { $_ -match "\S" } | ForEach-Object { $_.Trim() }

# 2. Iterate local configs
$LocalConfigDir = Join-Path $ProjectRoot "configs"
if (Test-Path $LocalConfigDir) {
    Get-ChildItem -Path $LocalConfigDir -Directory | ForEach-Object {
        $InstanceName = $_.Name
        
        if ($RemoteInstances -contains $InstanceName) {
            Write-Host "  Skipping '$InstanceName' (Exists on server)" -ForegroundColor DarkGray
        } else {
            Write-Host "  Uploading new instance: '$InstanceName'" -ForegroundColor Green
            
            # Create a clean version of this specific config (no saves)
            $TmpConfigInst = Join-Path $ProjectRoot "deploy_config_tmp_$InstanceName"
            New-Item -ItemType Directory -Path $TmpConfigInst | Out-Null
            
            # Copy contents excluding saves/zips
            Get-ChildItem -Path $_.FullName | Where-Object { $_.Name -ne "saves" -and $_.Extension -ne ".zip" } | ForEach-Object {
                Copy-Item -Recurse -Path $_.FullName -Destination $TmpConfigInst
            }
            
            # Upload this single instance folder
            $RemoteConfigParent = "$RemoteDir/configs/$InstanceName"
            # Ensure parent exists (mkdir is done in step 3 but redundant safety is cheap)
            
            if ($UsePutty) {
                # pscp to upload contents TO the folder requires folder to exist usually, or we upload folder name
                # Simplest: Upload the folder itself into configs/
                pscp.exe -r -i "$KeyPath" "$TmpConfigInst" "$ServerUser@$ServerIP`:$RemoteDir/configs/$InstanceName"
            } else {
                # scp -r local remote
                $SCPArgs = @("-r", "$TmpConfigInst", "$ServerUser@$ServerIP`:$RemoteDir/configs/$InstanceName")
                if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
                scp @SCPArgs
            }
            
            Remove-Item -Recurse -Force $TmpConfigInst
        }
    }
}

# 5. Execute Setup
Write-Host "Executing remote setup..." -ForegroundColor Cyan

# Script to run on server:
# 1. Fix line endings (dos2unix emulation with sed)
# 2. Make executable
# 3. Run check_resources
# 4. Run install_deps
$RemoteScript = "
    cd $RemoteDir
    find scripts -name '*.sh' -type f -exec sed -i 's/\r$//' {} +
    chmod +x scripts/manager.sh scripts/setup/*.sh games/*/*.sh
    
    echo '--- Running Resource Check ---
    ./scripts/setup/check_resources.sh
    
    echo '--- Running Dependency Install ---
    ./scripts/setup/install_deps.sh
    
    echo '--- Setup Complete ---
    echo 'You can now run ./scripts/manager.sh on the server.'
"

if ($UsePutty) {
    plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$RemoteScript"
} else {
    $SSHArgs = @("$ServerUser@$ServerIP", "$RemoteScript")
    if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
    ssh @SSHArgs
}

Write-Host "Deployment Finished." -ForegroundColor Green

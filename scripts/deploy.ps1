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

# 4. Upload Scripts
Write-Host "Uploading scripts..." -ForegroundColor Gray
# We upload the entire 'scripts', 'games', and 'configs' folders
# Exclude env (secrets) and .git

if ($UsePutty) {
    # pscp -r -i key source dest
    pscp.exe -r -i "$KeyPath" "$ProjectRoot\scripts" "$ServerUser@$ServerIP`:$RemoteDir/"
    pscp.exe -r -i "$KeyPath" "$ProjectRoot\games" "$ServerUser@$ServerIP`:$RemoteDir/"
    # Configs might be large if they have saves, but we need settings.
    # For now, upload configs too.
    pscp.exe -r -i "$KeyPath" "$ProjectRoot\configs" "$ServerUser@$ServerIP`:$RemoteDir/"
} else {
    $SCPArgs = @("-r", "$ProjectRoot/scripts", "$ProjectRoot/games", "$ProjectRoot/configs", "$ServerUser@$ServerIP`:$RemoteDir/")
    if ($KeyPath) { $SCPArgs = @("-i", "$KeyPath") + $SCPArgs }
    scp @SCPArgs
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

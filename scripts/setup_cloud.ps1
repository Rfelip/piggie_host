# Cloud Setup Helper
# Injects the Rclone token from .env to the remote server.

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ProjectRoot "env\.env"

# Load Config
if (-not (Test-Path $EnvFile)) { Write-Host "No .env found." -ForegroundColor Red; exit 1 }
$Config = @{}
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)=(.*)$") {
        $Config[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$Token = $Config["RCLONE_TOKEN"]
$ServerIP = $Config["SERVER_IP"]
$ServerUser = if ($Config["SERVER_USER"]) { $Config["SERVER_USER"] } else { "root" }
$KeyPath = if ($Config["SSH_KEY_PATH"]) { Join-Path $ProjectRoot $Config["SSH_KEY_PATH"] } else { "" }

if (-not $Token) {
    Write-Host "Error: RCLONE_TOKEN not found in env/.env" -ForegroundColor Red
    Write-Host "Please run 'rclone authorize drive' locally and paste the JSON into .env"
    exit 1
}

# Determine SSH/Plink
$UsePutty = $false
if ($KeyPath -and $KeyPath.EndsWith(".ppk")) { $UsePutty = $true }

# Escape quotes for shell: The token is JSON, so it has double quotes.
# We need to wrap it in single quotes for the bash command.
# Powershell escaping is fun.
$SafeToken = $Token.Replace("'", "'\''") 

$RemoteCmd = "rclone config create gdrive drive config_is_local=false token='$SafeToken'"

Write-Host "Configuring 'gdrive' remote on $ServerIP..." -ForegroundColor Cyan

if ($UsePutty) {
    plink.exe -batch -ssh -i "$KeyPath" "$ServerUser@$ServerIP" "$RemoteCmd"
} else {
    $SSHArgs = @("$ServerUser@$ServerIP", "$RemoteCmd")
    if ($KeyPath) { $SSHArgs = @("-i", "$KeyPath") + $SSHArgs }
    ssh @SSHArgs
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success! Cloud backup configured." -ForegroundColor Green
} else {
    Write-Host "Failed to configure rclone." -ForegroundColor Red
}

# Connect to Server Script
# Reads configuration from env/.env and establishes an SSH connection.
param (
    [string]$RemoteCommand = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$envFile = Join-Path $ProjectRoot "env\.env"

if (-not (Test-Path $envFile)) {
    Write-Host "Error: Configuration file '$envFile' not found." -ForegroundColor Red
    exit 1
}

# Parse .env file
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

if (-not $SERVER_IP) {
    Write-Host "Error: SERVER_IP not set in .env" -ForegroundColor Red
    exit 1
}

$User = if ($SERVER_USER) { $SERVER_USER } else { "root" }
$Key = if ($SSH_KEY_PATH) { $SSH_KEY_PATH } else { "" }
$UsePutty = ($Key -and $Key.EndsWith(".ppk"))

Write-Host "Connecting to $User@$SERVER_IP..." -ForegroundColor Cyan

# Check for OpenSSH Key format if using native ssh
if ($UsePutty) {
    Write-Host "Warning: Native SSH does not support .ppk files directly." -ForegroundColor Yellow
    Write-Host "Please convert '$Key' to OpenSSH format (e.g., id_rsa) using PuTTYgen:" -ForegroundColor Yellow
    Write-Host "  1. Load .ppk in PuTTYgen" -ForegroundColor Gray
    Write-Host "  2. Go to Conversions > Export OpenSSH key" -ForegroundColor Gray
    Write-Host "  3. Save as 'server_key' (no extension or .pem)" -ForegroundColor Gray
    Write-Host "  4. Update SSH_KEY_PATH in .env" -ForegroundColor Gray
    Write-Host ""
    
    $Choice = Read-Host "Do you want to try connecting using PuTTY (plink.exe) instead? (y/n)"
    if ($Choice -eq 'y') {
        if (Get-Command plink.exe -ErrorAction SilentlyContinue) {
            plink.exe -ssh -i "$Key" "$User@$SERVER_IP"
            exit
        } else {
            Write-Host "Error: plink.exe (PuTTY CLI) not found in PATH." -ForegroundColor Red
            exit 1
        }
    }
}

# Build SSH Command
$SSHArgs = @("$User@$SERVER_IP")
if ($Key -and -not $Key.EndsWith(".ppk")) {
    $SSHArgs += "-i"
    $SSHArgs += "$Key"
}

if ($RemoteCommand) {
    if ($UsePutty) {
        # Plink expects command as the last argument
        plink.exe -ssh -i "$Key" "$User@$SERVER_IP" -t "$RemoteCommand"
        exit
    } else {
        $SSHArgs += "-t" # Force pseudo-terminal for interactive menus
        $SSHArgs += "$RemoteCommand"
    }
} else {
     # Interactive shell fallback for Plink
     if ($UsePutty) {
        plink.exe -ssh -i "$Key" "$User@$SERVER_IP"
        exit
     }
}

ssh @SSHArgs

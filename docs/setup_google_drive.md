# Setting up Google Drive Backups

This guide explains how to configure automated cloud backups to Google Drive using `rclone`. This project supports "Headless Authentication," allowing you to authorize the server without a browser.

## Prerequisites

1.  **Rclone** installed on your **local machine** (Windows/Mac/Linux).
    *   Download: [https://rclone.org/downloads/](https://rclone.org/downloads/)
    *   Ensure `rclone.exe` is in your PATH or you know where it is.

## Step 1: Generate Access Token (Local)

Run the following command in your local terminal (PowerShell or CMD):

```powershell
rclone authorize "drive"
```

1.  A browser window will open.
2.  Log in to the Google Account you wish to use for backups.
3.  Grant Rclone access.
4.  Return to your terminal. You will see a large JSON block (the token).

**Example Token:**
```json
{"access_token":"ya29.a0...","token_type":"Bearer","refresh_token":"1//04...","expiry":"2026-01-01T00:00:00.0000000+00:00"}
```

## Step 2: Configure Environment

1.  Open the `env/.env` file in your project root.
2.  Paste the **entire JSON string** into the `RCLONE_TOKEN` variable. Ensure it is wrapped in single quotes to handle special characters.

**env/.env:**
```ini
SERVER_IP=192.168.1.100
SERVER_USER=root
SSH_KEY_PATH=./env/pvk.ppk
RCLONE_TOKEN='{"access_token":"ya29...","token_type":"Bearer",...}'
```

## Step 3: Inject Configuration

1.  Run the main orchestrator:
    ```powershell
    .\main.ps1
    ```
2.  Select **Option 4: Setup Cloud Auth (Inject Token)**.
3.  The script will connect to your server and configure the `gdrive` remote automatically.

## Step 4: Verify

1.  Connect to the remote manager (`Option 2` in `main.ps1`).
2.  The "Cloud Config Check" in the main menu should no longer show a warning.
3.  You can now enable Auto-Backups in the "Manage Servers" menu.

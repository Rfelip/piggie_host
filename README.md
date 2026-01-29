# Universal Game Server Manager

A generic, lightweight, and dependency-free utility for hosting game servers (Factorio, Minecraft, Terraria, etc.) on Linux servers from a Windows host.

## Features

*   **Generic Plugin Architecture:** Supports any game via simple `games/` scripts.
*   **Orchestrated Workflow:** One-click deployment from local machine to remote server.
*   **Interactive Manager:** Remote terminal UI for installing games, managing instances, and editing settings.
*   **State Tracking:** Tracks installation progress (Red/Green status) for different game engines.
*   **Advanced Save Handling:** Synchronize saves (Upload/Download) and perform Quick Backups with automatic timestamping.
*   **Resource Optimized:** Minimal overhead by running directly on the OS ("Bare Metal").

## Project Structure

*   `main.ps1`: **The Main Entry Point.** Local PowerShell script to deploy, manage, or sync saves.
*   `scripts/`:
    *   `deploy.ps1`: Orchestrates file upload and environment bootstrapping.
    *   `manager.sh`: The interactive Bash UI that runs on the server.
    *   `sync_saves.ps1`: Local utility for transferring game saves.
    *   `connect.ps1`: Helper for SSH/Plink connections.
    *   `setup/`: Modular remote setup scripts (Resource check, Deps).
*   `games/`: Game-specific logic plugins (Factorio, Minecraft, Terraria).
    *   `install.sh` / `start.sh`: Engine-specific lifecycle scripts.
    *   `game.ini`: Metadata for save formats and paths.
    *   `install_config.ini`: Tracks local installation state.
*   `configs/`: Server instances (e.g., `TBR2026`).
    *   `settings.sh`: System config for the manager.
*   `env/`: Local configuration and SSH keys (Ignored by Git).

## Usage

1.  **Configure:** 
    Place your SSH key in `env/` and edit `env/.env` with your `SERVER_IP` and `SERVER_USER`.
    
2.  **Run the Orchestrator:**
    ```powershell
    .\main.ps1
    ```
    *   **Option 1 (Deploy):** Uploads scripts and installs dependencies (Screen, Tmux, Java, etc.) on the server.
    *   **Option 2 (Manage):** Connects to the remote server and opens the Interactive Manager.
    *   **Option 3 (Sync):** Opens the Save Manager to upload, download, or backup your worlds.

3.  **In the Remote Manager:**
    *   Use **"Install Game"** to download binaries (Installed games appear in **Green**).
    *   Use **"Manage Servers"** to Start, Stop, or Edit settings.

## To-Do List

- [x] Refactor into a pure Bash `manager.sh`.
- [x] Implement generic `games/` plugin structure.
- [x] Create modular setup scripts (Resource check, Deps).
- [x] Create deployment orchestrator (`deploy.ps1`).
- [x] Add Minecraft and Terraria support.
- [x] Implement Advanced Save Handling (Sync & Quick Backup).
- [ ] Implement automated server-side backup scheduling (Cron).
- [ ] Add "Auto-start on boot" systemd generator.
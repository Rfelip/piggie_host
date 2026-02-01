# Universal Game Server Manager

A generic, lightweight, and dependency-free utility for hosting game servers on Linux servers from a Windows host.

## Supported Games

*   **Factorio** (Native Linux / Box64 on ARM)
*   **Minecraft** (Java Edition)
*   **Terraria** (Native Linux / Box64 on ARM)
*   **Barotrauma** (via SteamCMD / Box64 on ARM)
*   *More coming soon (Valheim, etc.)*

## Features

*   **Generic Plugin Architecture:** Supports any game via simple `games/` scripts.
*   **Orchestrated Workflow:** One-click deployment from local machine to remote server.
*   **Interactive Manager:** Remote terminal UI for installing games, managing instances, and editing settings.
*   **State Tracking:** Tracks installation progress (Red/Green status) for different game engines.
*   **Advanced Save Handling:** Synchronize saves (Upload/Download) and perform Quick Backups with automatic timestamping.
*   **Automated Backups:** Scheduled local backups with **Google Drive Sync** (via Rclone).
*   **Resource Optimized:** Minimal overhead by running directly on the OS ("Bare Metal").
*   **ARM Ready:** Built-in support for Arch Linux ARM and Box64 emulation.

## Project Structure

*   `main.ps1`: **The Main Entry Point.** Local PowerShell script to orchestrate the environment.
*   `scripts/`: Core logic and utilities.
    *   `deploy.ps1`: (Local) Pushes code and setup to remote.
    *   `sync_saves.ps1`: (Local) Synchronizes game saves.
    *   `sync_configs.ps1`: (Local) Synchronizes instance configurations.
    *   `setup/install_steamcmd.sh`: Automated SteamCMD installation.
*   `games/`: Game plugins (Directory for each supported game).
*   `configs/`: Server instances (e.g., `TBR2026`).
*   `docs/`: Detailed documentation and guides.

## Quick Start

1.  **Configure:** 
    *   Create `env/.env` (see `.env.example`).
    *   Add your SSH Key (`env/pvk.ppk`).
    
2.  **Deploy:**
    ```powershell
    .\main.ps1
    ```
    Select **Option 1 (Deploy)** to install dependencies and upload scripts.

3.  **Manage:**
    Select **Option 2 (Connect)** to open the Remote Manager.

## Documentation & Tutorials

*   **[Setting up Google Drive Backups](docs/setup_google_drive.md):** How to configure cloud backups using "Headless Auth".
*   **[Adding New Games](docs/adding_games.md):** Guide to creating plugins for new games (Valheim, CS:GO, etc.).
*   **[Oracle Cloud Guide](docs/oracle_cloud.md):** Important networking setup for Oracle Ampere VPS users.
*   **[Troubleshooting & Recovery](docs/troubleshooting.md):** Common issues, recovery from disconnects, and performance tuning.

## To-Do List
- [x] **Feature:** Handle Server Updates (Version checking/Force Reinstall).
- [x] **Feature:** Automated `box64` and `box86` installer for ARM.
- [ ] **Feature:** Add Valheim support.

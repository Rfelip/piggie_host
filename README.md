# Universal Game Server Manager

A generic, lightweight, and dependency-free utility for hosting game servers (Factorio, Minecraft, Terraria, etc.) on Linux servers from a Windows host.

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

*   `main.ps1`: **The Main Entry Point.** Local PowerShell script to deploy, manage, or sync saves.
*   `scripts/`: Core logic and utilities.
*   `games/`: Game plugins (Factorio, Minecraft, Terraria).
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
*   **[Troubleshooting & Recovery](docs/troubleshooting.md):** Common issues, recovery from disconnects, and performance tuning.

## Roadmap

- [x] Refactor into a pure Bash `manager.sh`.
- [x] Implement generic `games/` plugin structure.
- [x] Create modular setup scripts (Resource check, Deps).
- [x] Create deployment orchestrator (`deploy.ps1`).
- [x] Add Minecraft and Terraria support.
- [x] Implement Advanced Save Handling (Sync & Quick Backup).
- [x] Implement automated server-side backup scheduling (Cron).
- [x] Add "Auto-start on boot" systemd generator.
- [x] **Improvement:** Optimize deployment (Don't overwrite `configs/` or `saves/` blindly).
- [x] **Feature:** Handle Server Updates (Version checking/Force Reinstall).

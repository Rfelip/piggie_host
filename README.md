# Universal Game Server Manager

A generic, lightweight, and dependency-free Bash utility for hosting game servers (Factorio, Minecraft, Terraria, etc.) on Linux.

## Features

*   **Generic Architecture:** Supports any game via scripts in `games/`.
*   **Zero Dependencies:** Runs on pure Bash and `screen`/`tmux`. No Python or complex runtimes required.
*   **Simple Configuration:** Server instances are defined using `settings.sh` files.
*   **Automated Deployment:** Deploy scripts to remote servers and bootstrap the environment automatically.
*   **Resource Efficient:** Runs directly on the OS ("bare metal") to maximize performance on low-end hardware. **No Docker overhead.**

## Project Structure

*   `scripts/`: Executable utilities.
    *   `deploy.ps1`: **(Main)** Orchestrates deployment to the remote server.
    *   `connect.ps1`: Helper to SSH into the server.
    *   `manager.sh`: The server-side manager (runs on the remote host).
    *   `setup/`: Modular setup scripts (run on the remote host).
        *   `check_resources.sh`: Analyzes RAM, CPU, and Disk.
        *   `install_deps.sh`: Installs dependencies and handles `screen`/`tmux` fallback.
*   `games/`: Game-specific logic.
    *   `factorio/`: `install.sh` and `start.sh`.
*   `configs/`: Server instances.
    *   `TBR2026/settings.sh`: Configuration for a specific server instance.
*   `env/`: Local configuration and secrets (ignored by Git).

## Usage

1.  **Configure:**
    *   Edit `env/.env` with your server details.

2.  **Deploy & Setup:**
    *   Run the deployment script from your local machine:
        ```powershell
        .\scripts\deploy.ps1
        ```
    *   This will upload the manager, check remote resources, and install dependencies.

3.  **Manage Servers:**
    *   Connect to the server:
        ```powershell
        .\scripts\connect.ps1
        ```
    *   Run the manager:
        ```bash
        ./manager.sh
        ```

## FAQ

**Q: Why not Docker?**
A: Docker introduces memory overhead and file system complexity. On basic/low-end Linux servers (e.g., 1 vCPU, 1GB RAM), every megabyte counts. Running the servers directly allows the OS to manage resources more efficiently and avoids the "layer" penalty of containerization.

## To-Do List

- [x] Refactor into a pure Bash `manager.sh`.
- [x] Implement generic `games/` plugin structure.
- [x] Create modular setup scripts (Resource check, Deps).
- [x] Create deployment orchestrator (`deploy.ps1`).
- [ ] Add Minecraft/Terraria support.
- [ ] Implement automated backup functionality.
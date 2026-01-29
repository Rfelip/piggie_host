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



1.  **Start the Master Script:**

    *   Run the main script from your local machine. This orchestrates the entire process: deployment, setup, and remote management.

        ```powershell

        .\main.ps1

        ```

    *   It will connects to the server, update the environment, and then launch the **Interactive Manager**.



2.  **Interactive Manager (Remote):**

    *   **Install Games:** Select a game to install. Completed steps (deps, download) are tracked.

    *   **Run Servers:** Start/Stop configured server instances.

    *   **Auto-Start:** (Planned) Configure servers to start on boot.



## Project Structure



*   `main.ps1`: **(Main Entry)** Local script that runs deploy and then connects to the manager.

*   `scripts/`: Executable utilities.

    *   `deploy.ps1`: Uploads scripts and runs setup on the remote host.

    *   `manager.sh`: The interactive remote menu system.

*   `games/`: Game definitions and installers.

    *   `factorio/`:

        *   `install.sh`: Installation logic.

        *   `start.sh`: Startup logic.

        *   `install_config.ini`: Tracks installation state (deps, engine, etc.).

*   `configs/`: Server instances (e.g., `TBR2026`).



## To-Do List



- [x] Refactor into a pure Bash `manager.sh`.

- [x] Implement generic `games/` plugin structure.

- [x] Create modular setup scripts (Resource check, Deps).

- [x] Create deployment orchestrator (`deploy.ps1`).

- [ ] **Create Root `main.ps1`** to unify deploy and execution.

- [ ] **Refactor `manager.sh`:**

    - [ ] Add Main Menu (Install, Run, Config).

    - [ ] Implement state tracking (Green/Red status).

    - [ ] Add `install_config` parsing.

- [ ] Add Minecraft/Terraria support.

- [ ] Implement automated backup functionality.

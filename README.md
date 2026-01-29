# Universal Game Server Manager

A generic, lightweight, and dependency-free Bash utility for hosting game servers (Factorio, Minecraft, Terraria, etc.) on Linux.

## Features

*   **Generic Architecture:** Supports any game via scripts in `games/`.
*   **Zero Dependencies:** Runs on pure Bash and `screen`. No Python or complex runtimes required.
*   **Simple Configuration:** Server instances are defined using `settings.sh` files.
*   **Automated Workflow:** Detects if a game is installed; if not, it runs the installation script automatically.

## Project Structure

*   `manager.sh`: The main entry point (Bash).
*   `setup_env.sh`: Installs system dependencies (`screen`, `wget`, etc.).
*   `games/`: Game-specific logic.
    *   `factorio/`: `install.sh` and `start.sh`.
*   `configs/`: Server instances.
    *   `TBR2026/settings.sh`: Configuration for a specific server instance.

## Usage

1.  **Initialize Environment:**
    ```bash
    chmod +x setup_env.sh
    ./setup_env.sh
    ```

2.  **Run the Manager:**
    ```bash
    chmod +x manager.sh
    ./manager.sh
    ```

3.  **Add a New Server:**
    *   Create `configs/my-server/settings.sh`.
    *   Set `GAME="gamename"` and other variables.
    *   Ensure `games/gamename/` has `install.sh` and `start.sh`.

## To-Do List

- [x] Refactor into a pure Bash `manager.sh`.
- [x] Implement generic `games/` plugin structure.
- [ ] Add `games/minecraft/` scripts.
- [ ] Add `games/terraria/` scripts.
- [ ] Implement automated backup functionality.

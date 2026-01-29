# Adding New Games

The Game Server Manager uses a plugin-based architecture. Adding support for a new game requires creating a directory in `games/` with specific scripts.

## Directory Structure

Create a folder `games/<game_name>/` containing the following files:

1.  **`install.sh`**: Downloads and sets up the game binaries.
2.  **`update.sh`**: Updates the binaries (overwriting old ones safely).
3.  **`start.sh`**: The command to launch the server process.
4.  **`check_state.sh`**: Checks if the game is installed (Green/Yellow status).
5.  **`game.ini`**: Metadata for save handling.
6.  **`install_config.ini`**: Tracks installation state.

## File Details

### 1. install.sh
*   **Input:** `$1` (Install Path)
*   **Task:** Download archives, extract them, install dependencies (e.g., `apt-get install unzip`), and cleanup.
*   **Output:** Must update `install_config.ini` (`game_installed=1`) upon success.

### 2. start.sh
*   **Input:** `$1` (Install Path), `$2` (Save File Path), `$3` (Settings File Path).
*   **Task:** Exec the game binary.
*   **Important:** Do **not** run `screen` here. The manager handles session management. Just run the blocking process.
*   **ARM Support:** If the game is x86_64 only, use `box64` wrapper for ARM architecture.

### 3. game.ini
Defines how the manager handles saves.

```ini
[Metadata]
name=MyGame
save_format=folder  # 'folder' or 'zip'
default_save_dir=saves
```

## Example Workflow

To add **Valheim**:
1.  Create `games/valheim/`.
2.  Write `install.sh` using `steamcmd` to download Valheim.
3.  Write `start.sh` to run `./valheim_server.x86_64`.
4.  Define `game.ini` with `save_format=folder` (worlds are in `~/.config/unity3d/...`).
5.  Run `./main.ps1` to deploy the new scripts.
6.  The new game will automatically appear in the "Install Game" menu.

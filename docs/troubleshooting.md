# Troubleshooting & Recovery

## Connection Issues

### Lost SSH Connection
**Symptom:** The terminal freezes or closes.
**Impact:** Game servers continue running in background `screen` sessions.
**Recovery:**
1.  Run `.\main.ps1`.
2.  Select **Option 2 (Connect)**.
3.  Once in the manager, select **Manage Servers** -> **View Console** to re-attach.

### SSH Timeout
**Symptom:** "Connection reset by peer" after inactivity.
**Fix:** The connection script uses KeepAlive. If this persists, check your server's `sshd_config` (ClientAliveInterval).

## Deployment Issues

### Overwritten Configs
**Symptom:** Remote settings were reset after a deploy.
**Cause:** Local configuration files overwrote remote ones.
**Prevention:** The deployment script checks for existing instances and **skips** uploading config folders if they exist remotely.
**Fix:** Edit the settings manually on the server using the Manager ("Edit Game System Configs").

## Runtime Issues

### Server Crash on Boot
**Symptom:** Server shows "Stopped" immediately after "Start".
**Debug:**
1.  Try starting manually (Manager -> Start Server).
2.  If it fails, check logs in the instance folder (`logs/` if the game creates them) or run the `start.sh` command manually in a shell to see stderr.

### "Low Disk Space" Warning
**Symptom:** Manager displays red warning.
**Fix:**
1.  Check for old backups (`backups/`).
2.  Check for large log files.
3.  Run `apt-get clean` to remove cached packages.

### "Low RAM" Warning
**Symptom:** Games crash randomly (OOM Killer).
**Fix:**
1.  Enable Swap: Create a swap file (e.g., 2GB) to prevent crashes.
2.  Reduce JVM Heap: Edit `settings.sh` for Minecraft and lower `MC_RAM_MAX`.

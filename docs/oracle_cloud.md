# Oracle Cloud Setup Guide

Running Piggie Host on Oracle Cloud (ARM Ampere) is highly recommended due to the generous free tier resources (4 OCPUs, 24GB RAM). However, networking can be tricky.

## 1. The "Double Firewall" Problem

To make your game server visible to the internet, you must open ports in **TWO** places:
1.  **Oracle Cloud Console** (Virtual Cloud Network Security List).
2.  **The Server OS** (iptables/ufw/firewalld).

If you miss either one, nobody can connect.

## 2. Step 1: Oracle Cloud Console (Ingress Rules)

1.  Log in to the **Oracle Cloud Console**.
2.  Go to **Networking** -> **Virtual Cloud Networks**.
3.  Click on your active **VCN**.
4.  Click **"Security Lists"** (usually on the left).
5.  Click the **"Default Security List"**.
6.  Click **"Add Ingress Rules"**.
7.  Add the following rule for your game:
    *   **Source CIDR:** `0.0.0.0/0` (Allow everyone)
    *   **Protocol:** `TCP` (For Minecraft/Terraria) or `UDP` (For Factorio/Bedrock)
    *   **Destination Port Range:** (e.g., `25565`)
    *   **Description:** "Minecraft Server"

### Common Ports
*   **Minecraft (Java):** 25565 (TCP)
*   **Factorio:** 34197 (UDP)
*   **Terraria:** 7777 (TCP)

## 3. Step 2: OS-Level Firewall (Arch Linux / Oracle Linux)

Oracle instances often have strict `iptables` rules by default.

### For Arch Linux (Using iptables/nftables)
Arch usually doesn't block ports by default unless you installed a firewall. If you cannot connect, check your rules:

```bash
sudo iptables -L -n
```

To allow a port (e.g., 25565 TCP) temporarily:
```bash
sudo iptables -I INPUT -p tcp --dport 25565 -j ACCEPT
```
*Note: You need to save these rules to make them persistent (e.g., `iptables-save`).*

### For Oracle Linux / CentOS (Using firewalld)
```bash
# Open TCP port (Minecraft/Terraria)
sudo firewall-cmd --permanent --zone=public --add-port=25565/tcp
sudo firewall-cmd --reload

# Open UDP port (Factorio)
sudo firewall-cmd --permanent --zone=public --add-port=34197/udp
sudo firewall-cmd --reload
```

### For Ubuntu (Using UFW)
```bash
sudo ufw allow 25565/tcp
sudo ufw allow 34197/udp
```

## 4. Performance Tuning (ARM Ampere)

Your instance has 4 OCPUs. Java (Minecraft) handles this well, but Factorio/Terraria running through `box64` are single-threaded heavy.

*   **Box64:** Ensure you are using the latest version of `box64`. It is incredibly efficient on Oracle Ampere chips.
*   **Java Arguments:** In `settings.sh`, you can comfortably allocate 12-16GB RAM to Minecraft if you have the 24GB instance.

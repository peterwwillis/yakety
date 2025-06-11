# WSL SSH Remote Access Guide

This guide helps you set up SSH access to your WSL instance from remote machines on your local network using the provided scripts.

## Overview

WSL2 runs in a virtualized network environment, so you need to:
1. Configure SSH in WSL
2. Set up port forwarding from Windows to WSL
3. Configure Windows Firewall

## Scripts Included

### 1. `setup-wsl-ssh.sh` - WSL SSH Setup (Run Once)
This bash script configures SSH server in WSL with:
- OpenSSH server installation
- Port 22 configuration
- Public key authentication enabled
- Auto-start on WSL launch
- Proper permissions for SSH directories

```bash
#!/bin/bash
# WSL SSH Setup Script - Run once to configure SSH in WSL

set -e

echo "=== WSL SSH Setup Script ==="
echo "This script will configure OpenSSH server in WSL"
echo

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "Please run this script as a normal user, not as root"
   exit 1
fi

# Update packages
echo "Updating package list..."
sudo apt update

# Install OpenSSH server if not already installed
if ! command -v sshd &> /dev/null; then
    echo "Installing OpenSSH server..."
    sudo apt install -y openssh-server
else
    echo "OpenSSH server is already installed"
fi

# Backup original sshd_config
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    echo "Backing up original SSH config..."
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi

# Configure SSH
echo "Configuring SSH server..."
sudo tee /etc/ssh/sshd_config.d/wsl.conf > /dev/null << 'EOF'
# WSL SSH Configuration
Port 22
ListenAddress 0.0.0.0
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin prohibit-password
X11Forwarding yes
EOF

# Enable SSH to start automatically
echo "Enabling SSH auto-start..."
sudo systemctl enable ssh 2>/dev/null || echo "Note: systemctl not available, SSH may need manual start"

# Create .ssh directory if it doesn't exist
if [ ! -d ~/.ssh ]; then
    echo "Creating .ssh directory..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

# Create authorized_keys file if it doesn't exist
if [ ! -f ~/.ssh/authorized_keys ]; then
    echo "Creating authorized_keys file..."
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Start SSH service
echo "Starting SSH service..."
sudo service ssh start

# Check SSH status
if sudo service ssh status | grep -q "is running"; then
    echo
    echo "✓ SSH server is running successfully!"
else
    echo
    echo "✗ SSH server failed to start. Check logs with: sudo journalctl -u ssh"
    exit 1
fi

# Get WSL IP
WSL_IP=$(hostname -I | awk '{print $1}')
echo
echo "=== Setup Complete ==="
echo "SSH is configured on port 22 with public key authentication enabled"
echo "WSL IP address: $WSL_IP"
echo
echo "Next steps:"
echo "1. Add your SSH public key to ~/.ssh/authorized_keys"
echo "2. Run the Windows batch script to set up port forwarding"
echo "3. Connect using: ssh $USER@<windows-host-ip>"
echo
echo "To disable password authentication after setting up keys:"
echo "sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config.d/wsl.conf"
echo "sudo service ssh restart"
```

### 2. `start-wsl-ssh.bat` - Windows Port Forwarding (Run on Each Boot)
This batch script:
- Starts WSL if not running
- Gets the current WSL IP address
- Sets up port forwarding from Windows port 22 to WSL port 22
- Configures Windows Firewall
- Shows your Windows IP for remote connections

```batch
@echo off
REM Windows batch script to start WSL and set up SSH port forwarding
REM Run this script as Administrator

echo === WSL SSH Startup Script ===
echo.

REM Start WSL in the background
echo Starting WSL...
wsl --exec echo "WSL is running" > nul 2>&1

REM Wait a moment for WSL to fully start
timeout /t 2 /nobreak > nul

REM Get WSL IP address
echo Getting WSL IP address...
for /f "tokens=1" %%i in ('wsl hostname -I') do set WSL_IP=%%i

if "%WSL_IP%"=="" (
    echo ERROR: Could not get WSL IP address. Is WSL running?
    pause
    exit /b 1
)

echo WSL IP: %WSL_IP%
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click the script and select "Run as administrator"
    pause
    exit /b 1
)

REM Remove all existing port forwarding rules
echo Removing existing port forwarding rules...
netsh interface portproxy reset

REM Add port forwarding for SSH (port 22)
echo Setting up port forwarding for SSH (port 22)...
netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=22 connectaddress=%WSL_IP%

REM Create firewall rule if it doesn't exist
echo Checking firewall rules...
netsh advfirewall firewall show rule name="WSL SSH Port 22" >nul 2>&1
if %errorLevel% neq 0 (
    echo Creating firewall rule for port 22...
    netsh advfirewall firewall add rule name="WSL SSH Port 22" dir=in action=allow protocol=TCP localport=22
) else (
    echo Firewall rule already exists
)

REM Show current port forwarding rules
echo.
echo Current port forwarding rules:
netsh interface portproxy show v4tov4

REM Get Windows IP address
echo.
echo Your Windows host IP addresses:
echo ================================
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do echo %%i

echo.
echo === Setup Complete! ===
echo To connect from a remote machine:
echo ssh username@[windows-ip-address]
echo.
pause
```

## Setup Instructions

### Step 1: Initial WSL Setup (One Time)

1. Open WSL terminal
2. Navigate to the script directory:
   ```bash
   cd /mnt/c/workspaces/yakety
   ```
3. Run the setup script:
   ```bash
   ./setup-wsl-ssh.sh
   ```

### Step 2: Windows Port Forwarding (Run After Each Windows Restart)

1. Navigate to `C:\workspaces\yakety` in Windows Explorer
2. Right-click `start-wsl-ssh.bat` and select "Run as administrator"
3. The script will show your Windows IP address

### Step 3: Connect from Remote Machine

```bash
ssh username@windows-ip-address
```

Example:
```bash
ssh badlogic@192.168.1.100
```

### Optional: SSH Key Authentication

To use SSH keys instead of passwords, add your public keys to `~/.ssh/authorized_keys` in WSL. After setting up keys, you can disable password authentication for better security.

## Troubleshooting

### SSH Connection Refused
1. Check SSH is running in WSL:
   ```bash
   sudo service ssh status
   ```
2. Verify port forwarding:
   ```cmd
   netsh interface portproxy show v4tov4
   ```

### Cannot Get WSL IP
1. Make sure WSL is running:
   ```cmd
   wsl --list --running
   ```
2. Start WSL manually:
   ```cmd
   wsl
   ```

### Permission Denied
1. Check SSH key permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```
2. Check SSH logs:
   ```bash
   sudo journalctl -u ssh -f
   ```

## Claude Code Integration

Once SSH is working, you can use Claude Code on macOS to work directly on your Windows development environment:

### Setup for Claude Code

1. **Tell Claude Code about your Windows machine:**
   ```
   My Windows machine is accessible at 192.168.1.21 via SSH using username 'badlogic'.
   I can run Windows commands using: ssh badlogic@192.168.1.21 "cmd.exe /c command"
   The Yakety workspace is at: /mnt/c/workspaces/yakety/
   ```

2. **Claude Code can then:**
   - Read files: `ssh badlogic@192.168.1.21 "cat /mnt/c/workspaces/yakety/src/main.c"`
   - Write files: `echo "content" | ssh badlogic@192.168.1.21 "cat > /mnt/c/workspaces/yakety/file.txt"`
   - Build projects: `ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && cmd.exe /c 'c:\workspaces\winvs.bat' cmake --build --preset release"`
   - Sync from local: `rsync -av src/ badlogic@192.168.1.21:/mnt/c/workspaces/yakety/src/`

### Recommended Workflow

1. **Develop on macOS** (fast local tools, native Claude Code)
2. **Sync changes** using rsync to Windows machine  
3. **Build/test on Windows** via SSH commands
4. **Pull results back** if needed using scp

Example Claude Code prompt:
```
"I have a Windows machine at 192.168.1.21 accessible via SSH (username: badlogic). 
The Yakety project is at /mnt/c/workspaces/yakety/. Please sync my local src/ 
directory to Windows and then build the release version using the winvs.bat script."
```

Claude Code can then execute commands like:
```bash
rsync -av src/ badlogic@192.168.1.21:/mnt/c/workspaces/yakety/src/
ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && cmd.exe /c 'c:\workspaces\winvs.bat' cmake --build --preset release"
```

## Quick Reference

**WSL Commands:**
```bash
# Check SSH status
sudo service ssh status

# Restart SSH
sudo service ssh restart

# View SSH config
cat /etc/ssh/sshd_config.d/wsl.conf
```

**Windows Commands:**
```cmd
# Show port forwarding
netsh interface portproxy show v4tov4

# Remove all port forwarding
netsh interface portproxy reset

# Get Windows IP
ipconfig | findstr /i "IPv4"
```
# WSL Environment & Virtual Machines Manager

A complete workspace, interactive automation batch script, and reference guide for managing custom Windows Subsystem for Linux (WSL) virtual environments (such as `Ubuntu-rust`, `Debian-go`, `Arch-dev`, etc.).

All VM virtual hard disks (`ext4.vhdx`), exports (`.tar`, `.tar.gz`), and `.wsl` packages are managed and isolated inside the dedicated [VMs](file:///D:/Virtual%20Environments/WSL/VMs) directory.

---

## ?? Repository Structure

* **[wsl-manager.bat](file:///D:/Virtual%20Environments/WSL/wsl-manager.bat)**: Interactive Windows batch script for automated WSL availability checking, custom-named VM creation, imports, exports, selective stopping, disk optimization, and lifecycle operations inside `VMs\`.
* **[cheats.txt](file:///D:/Virtual%20Environments/WSL/cheats.txt)**: Fast command-line reference cheatsheet covering all WSL administration actions.
* **[sets-wsl-conf.txt](file:///D:/Virtual%20Environments/WSL/sets-wsl-conf.txt)**: Configuration template for `/etc/wsl.conf` (enabling systemd, configuring default user, disabling Windows PATH append, and adding VS Code PATH).
* **[du-excl-mnt.txt](file:///D:/Virtual%20Environments/WSL/du-excl-mnt.txt)**: Linux storage analysis command and output reference (excluding host `/mnt` mounts).
* **[VMs/](file:///D:/Virtual%20Environments/WSL/VMs)**: Root directory where all custom WSL instances and backup images reside.

### ?? Git Ignored Local Assets
Heavy virtual disks, backups, and machine binaries are excluded via [.gitignore](file:///D:/Virtual%20Environments/WSL/.gitignore):
* `VMs/*` (excluding `.gitkeep`) - All local virtual machines, disk images (`.vhdx`), and backup archives (`.tar`, `.tar.gz`, `.zip`, `.7z`).
* `*.wsl` - WSL package files.
* `*.ico` - Desktop shortcut icons.

---

## ? Interactive Batch Manager (`wsl-manager.bat`)

The repository includes a batch utility [wsl-manager.bat](file:///D:/Virtual%20Environments/WSL/wsl-manager.bat). Simply double-click or run from CMD / PowerShell:

```cmd
wsl-manager.bat
```

### Key Capabilities:
1. **WSL Availability Pre-Check**: Checks if `wsl.exe` is installed and available in PATH; provides clear instructions if missing.
2. **List Distributions**: Shows registered WSL distributions, versions, running states, plus folders and backup packages inside `VMs\`.
3. **Install Distribution**: Install from online repositories (e.g. `Ubuntu-24.04`, `Debian`, `kali-linux`) or from a `.wsl` file, assigning a custom instance name (e.g., `Ubuntu-rust`, `Debian-go`) and saving the instance directly into `VMs\<InstanceName>`. Automatically configures `/etc/wsl.conf` with `[interop] appendWindowsPath = false` and adds VS Code CLI (`code`) to Linux PATH via `/etc/profile.d/vscode.sh`.
4. **Import Distribution**: Detects `.tar`, `.tar.gz`, and `.vhdx` files inside `VMs\`, imports them as WSL 2 distributions under custom instance names into `VMs\<InstanceName>`, and sets up `/etc/wsl.conf` and VS Code PATH.
5. **Export Distribution**: Backs up any running or stopped distribution into `VMs\<InstanceName>.tar` or `VMs\<InstanceName>.vhdx` (via `--vhd`).
6. **Unregister / Delete**: Safely unregisters distributions with explicit confirmation, and provides an option to clean up the associated directory in `VMs\`.
7. **Selective Stop / Lifecycle**:
   * Terminate specific distributions.
   * **Stop all running EXCEPT specified whitelist** (e.g. `Ubuntu-js,Ubuntu-go`), with `Ubuntu` and `docker-desktop` permanently protected from being terminated.
   * Full WSL engine shutdown (`wsl --shutdown`).
8. **VHDX Disk Compacting**: Safely shuts down WSL and shrinks dynamically expanding `.vhdx` disks using `Optimize-VHD` or `diskpart` (with automated elevation and window closure), plus option to enable automatic Sparse VHD mode.

---

## ?? CLI Administration Cheatsheet

For manual administration, refer to the workflows below:

### 1. Install / Create Distro with Custom Name in `VMs\`
```powershell
# Online install with custom name and dedicated storage folder in VMs\
wsl --install Ubuntu-24.04 --name Ubuntu-rust --location .\VMs\Ubuntu-rust
wsl --install Debian --name Debian-go --location .\VMs\Debian-go

# Install from a local .wsl package file
wsl --install --from-file .\VMs\Ubuntu.wsl --name Ubuntu-rust --location .\VMs\Ubuntu-rust
```

### 2. Export & Backup into `VMs\`
```powershell
# Export distribution to a tar archive
wsl --export Ubuntu-rust .\VMs\Ubuntu-rust.tar

# Export distribution directly as a VHDX image
wsl --export Ubuntu-rust .\VMs\Ubuntu-rust.vhdx --vhd
```

### 3. Import Distro into `VMs\`
```powershell
# Import from a tarball archive as WSL 2
wsl --import Ubuntu-rust .\VMs\Ubuntu-rust .\VMs\Ubuntu-rust.tar --version 2

# Import from a VHDX virtual disk image
wsl --import Ubuntu-rust .\VMs\Ubuntu-rust .\VMs\Ubuntu-rust.vhdx --vhd

# In-place VHDX import
wsl --import-in-place Ubuntu-rust .\VMs\Ubuntu-rust\ext4.vhdx
```

### 4. Selective Stop (Stop all except whitelist)
```powershell
# Stop all running distributions except Ubuntu-js and Ubuntu-go (protecting Ubuntu and docker-desktop)
powershell -Command "$keep = @('Ubuntu-js','Ubuntu-go'); ((wsl -l --running -q | Out-String) -replace [char]0,'').Split([Environment]::NewLine,[StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -ne 'Ubuntu' -and $_ -ne 'docker-desktop' -and $keep -notcontains $_ } | ForEach-Object { wsl --terminate $_ }"
```

### 5. Unregister / Delete Distribution
```powershell
# Unregister distribution from WSL
wsl --unregister Ubuntu-rust
```

### 6. VHDX Disk Optimization (Shrinking Disk Size)
WSL `.vhdx` disks grow dynamically. To reclaim disk space after deleting files inside Linux:

```powershell
# Terminate the distribution / shut down WSL
wsl --terminate Ubuntu-rust
wsl --shutdown

# Run in PowerShell (Admin) to shrink the virtual disk size:
Optimize-VHD -Path .\VMs\Ubuntu-rust\ext4.vhdx -Mode Full
```

*(Alternatively, enable sparse VHD in modern WSL for automatic disk reclamation: `wsl --manage Ubuntu-rust --set-sparse true`)*.

---

## ?? Configuration Presets

### WSL System Settings (`/etc/wsl.conf`) & VS Code PATH
When importing or setting up a distro from scratch, configure `/etc/wsl.conf` ([sets-wsl-conf.txt](file:///D:/Virtual%20Environments/WSL/sets-wsl-conf.txt)):

```ini
# /etc/wsl.conf
[boot]
systemd=true

[user]
default=<username>

[interop]
appendWindowsPath = false
```

#### Making VS Code (`code`) accessible inside WSL
When `appendWindowsPath = false` is active, inject VS Code CLI into Linux `$PATH` via `/etc/profile.d/vscode.sh`:

```bash
# Inside WSL (or via wsl.exe -d <distro> -u root -- sh -c "...")
echo 'export PATH="$PATH:/mnt/c/Users/<your-windows-username>/AppData/Local/Programs/Microsoft VS Code/bin"' > /etc/profile.d/vscode.sh
chmod +x /etc/profile.d/vscode.sh
```

Or set the default user directly via WSL CLI:
```powershell
wsl --manage Ubuntu-rust --set-default-user <username>
```

### Disk Space Analysis
To inspect Linux filesystem usage without scanning Windows mount points ([du-excl-mnt.txt](file:///D:/Virtual%20Environments/WSL/du-excl-mnt.txt)):
```bash
sudo du -h --max-depth=1 --exclude=/mnt / | sort -h
```

---

## ?? Registered VM Path Query

To find the exact registry and physical disk paths of all installed WSL distros:

```powershell
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss\*" | 
    Select-Object DistributionName, BasePath
```

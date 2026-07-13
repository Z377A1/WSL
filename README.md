# WSL Environment & Virtual Machines Manager

This repository serves as a workspace and reference guide for managing custom Windows Subsystem for Linux (WSL) virtual environments, specifically tailored around the Ubuntu distribution. It contains configuration presets, disk management cheatsheets, and backup workflows.

---

## 📁 Repository Structure

*   **[sets.txt](file:///D:/Virtual%20Environments/WSL/sets.txt)**: Configuration template for `/etc/wsl.conf` within the WSL instance.
*   **[du-excl-mnt.txt](file:///D:/Virtual%20Environments/WSL/du-excl-mnt.txt)**: Script and reference output for disk space analysis within WSL, avoiding traversing Windows host mounts (`/mnt`).
*   **[Ubuntu/cheats.txt](file:///D:/Virtual%20Environments/WSL/Ubuntu/cheats.txt)**: A cheatsheet with essential WSL command-line actions for importing, exporting, and managing virtual disks.

### 🔒 Git Ignored Local Assets
To keep the repository lightweight, heavy binary files and environment backups are excluded via [.gitignore](file:///D:/Virtual%20Environments/WSL/.gitignore):
*   `Ubuntu/ext4.vhdx` - The active WSL virtual disk.
*   `Ubuntu/Ubuntu.tar.gz` - Compressed backup tarball export of the WSL image.
*   `*.ico` & `*.wsl` - Icons and configuration installers.

---

## ⚙️ Configuration & Customization

### WSL System Settings (`/etc/wsl.conf`)
Ensure your WSL environment is set up with `systemd` enabled and mapping to your default user. Refer to [sets.txt](file:///D:/Virtual%20Environments/WSL/sets.txt):

```ini
# /etc/wsl.conf
[boot]
systemd=true

[user]
default=<username>
```

---

## 🚀 WSL Administration Cheatsheet

Below is a reference of the operations documented in [Ubuntu/cheats.txt](file:///D:/Virtual%20Environments/WSL/Ubuntu/cheats.txt) and [du-excl-mnt.txt](file:///D:/Virtual%20Environments/WSL/du-excl-mnt.txt).

### 1. Installation & Import
To set up or restore a WSL instance from an existing tarball export and place its virtual disk (`.vhdx`) in the current directory:

```powershell
# Import from a backup file (Ubuntu.tar.gz) into the current directory
wsl --import Ubuntu .\ .\Ubuntu.tar.gz
```

Alternatively, installing from a `.wsl` installer file:
```powershell
wsl --install --from-file <filename>.wsl --name Ubuntu --location .\
```

### 2. Export & Backup
To back up your WSL distribution to a compressed tarball:

```powershell
# Export the 'Ubuntu' distribution to a tarball file in the current directory
wsl --export Ubuntu .\Ubuntu.tar.gz
```

### 3. VHDX Disk Optimization (Shrinking Disk Size)
WSL virtual disks (`ext4.vhdx`) grow dynamically but do not automatically shrink when files are deleted. Use PowerShell with administrative privileges to optimize the VHDX file:

```powershell
# Run in PowerShell (Admin) to shrink the virtual disk size
Optimize-VHD -path .\ext4.vhdx
```

### 4. WSL Disk Space Analysis
When running low on storage, use `du` inside the WSL instance. Ensure you exclude `/mnt` so that the command doesn't traverse your Windows filesystems:

```bash
# Run inside the WSL instance
sudo du -h --max-depth=1 --exclude=/mnt / | sort -h
```

---

## 📝 License & Notes
This is a private helper repository designed for local virtual machine maintenance.
For official Ubuntu WSL images, consult [Ubuntu Releases](https://releases.ubuntu.com).

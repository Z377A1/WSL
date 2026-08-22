param (
    [Parameter(Mandatory = $true)]
    [string]$DistroName,

    [Parameter(Mandatory = $false)]
    [string]$WinUser = $env:USERNAME
)

if (-not $WinUser) {
    $WinUser = "mdyar"
}

Write-Host "[*] Applying configuration to '$DistroName' for Windows user '$WinUser'..." -ForegroundColor Cyan

$wslConfContent = @"
[boot]
systemd=true

[interop]
enabled = true
appendWindowsPath = false
"@

$serviceContent = @"
[Unit]
Description=Ensure WSL Windows PE binary interop
DefaultDependencies=no
After=systemd-binfmt.service proc-sys-fs-binfmt_misc.mount
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "test -f /proc/sys/fs/binfmt_misc/WSLInterop || echo ':WSLInterop:M::MZ::/init:P' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true"
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
"@

$vscodeContent = @"
#!/bin/sh
test -f /proc/sys/fs/binfmt_misc/WSLInterop || echo ':WSLInterop:M::MZ::/init:P' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true
export PATH="/mnt/c/Users/$WinUser/AppData/Local/Programs/Microsoft VS Code/bin:`$PATH"
"@

# Write directly into WSL via stdin / tee
$wslConfContent.Replace("`r`n", "`n") | wsl.exe -d $DistroName -u root -- tee /etc/wsl.conf | Out-Null
$serviceContent.Replace("`r`n", "`n") | wsl.exe -d $DistroName -u root -- tee /etc/systemd/system/wsl-interop.service | Out-Null
wsl.exe -d $DistroName -u root -- systemctl enable wsl-interop.service | Out-Null
$vscodeContent.Replace("`r`n", "`n") | wsl.exe -d $DistroName -u root -- tee /etc/profile.d/vscode.sh | Out-Null
wsl.exe -d $DistroName -u root -- chmod +x /etc/profile.d/vscode.sh | Out-Null

wsl.exe --terminate $DistroName | Out-Null
Write-Host "[SUCCESS] Configuration successfully applied to '$DistroName'." -ForegroundColor Green

@echo off
setlocal EnableDelayedExpansion
title WSL VM Manager

:: -----------------------------------------------------------------------------
:: WSL VM Manager
:: Manages custom-named WSL instances (e.g. Ubuntu-rust, Debian-go) inside VMs\
:: -----------------------------------------------------------------------------

set "ROOT_DIR=%~dp0"
set "VM_DIR=%ROOT_DIR%VMs"

:: Ensure VMs directory exists
if not exist "%VM_DIR%" (
    mkdir "%VM_DIR%" >nul 2>&1
)

:: -----------------------------------------------------------------------------
:: CHECK WSL AVAILABILITY
:: -----------------------------------------------------------------------------
where wsl.exe >nul 2>&1
if %ERRORLEVEL% neq 0 goto WSL_NOT_FOUND
goto MAIN_MENU

:WSL_NOT_FOUND
cls
echo ===============================================================================
echo                          WSL NOT FOUND ERROR                                  
echo ===============================================================================
echo.
echo [ERROR] Windows Subsystem for Linux ^(WSL^) executable was not found on PATH.
echo.
echo To install WSL, open PowerShell as Administrator and execute:
echo     wsl --install
echo.
echo Press any key to exit...
pause >nul
exit /b 1


:: -----------------------------------------------------------------------------
:: MAIN MENU
:: -----------------------------------------------------------------------------
:MAIN_MENU
cls
echo ===============================================================================
echo                      WSL VIRTUAL MACHINE MANAGER                               
echo ===============================================================================
echo  VM Storage Directory: %VM_DIR%
echo ===============================================================================
echo.
echo   [1] List Installed Distributions ^(wsl -l -v^)
echo   [2] Install Distribution ^(Online or from .wsl file into VMs\^)
echo   [3] Import Distribution ^(.tar / .tar.gz / .vhdx into VMs\^)
echo   [4] Export Distribution ^(Backup distro into VMs\^)
echo   [5] Unregister / Delete Distribution
echo   [6] Launch / Run Distribution
echo   [7] Stop Distribution / Shutdown WSL
echo   [8] Optimize / Shrink VHDX Disk
echo   [9] Set Default Distribution
echo   [0] Exit
echo.
echo ===============================================================================
set /p "CHOICE=Select an option [0-9]: "

if "%CHOICE%"=="1" goto LIST_DISTROS
if "%CHOICE%"=="2" goto INSTALL_DISTRO
if "%CHOICE%"=="3" goto IMPORT_DISTRO
if "%CHOICE%"=="4" goto EXPORT_DISTRO
if "%CHOICE%"=="5" goto UNREGISTER_DISTRO
if "%CHOICE%"=="6" goto LAUNCH_DISTRO
if "%CHOICE%"=="7" goto STOP_DISTRO
if "%CHOICE%"=="8" goto OPTIMIZE_DISK
if "%CHOICE%"=="9" goto SET_DEFAULT
if "%CHOICE%"=="0" goto EXIT_SCRIPT

echo.
echo [!] Invalid selection. Please choose an option between 0 and 9.
ping 127.0.0.1 -n 2 >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 1. LIST DISTRIBUTIONS
:: -----------------------------------------------------------------------------
:LIST_DISTROS
cls
echo ===============================================================================
echo                         INSTALLED WSL DISTRIBUTIONS                            
echo ===============================================================================
echo.
wsl.exe --list --verbose
echo.
echo -------------------------------------------------------------------------------
echo  VM Folders in %VM_DIR%:
echo -------------------------------------------------------------------------------
dir /b /a:d "%VM_DIR%" 2>nul
if %ERRORLEVEL% neq 0 echo   - No subdirectories found in VMs\
echo.
echo -------------------------------------------------------------------------------
echo  Backup / Image Packages in %VM_DIR%:
echo -------------------------------------------------------------------------------
dir /b /a:-d "%VM_DIR%\*.tar" "%VM_DIR%\*.tar.gz" "%VM_DIR%\*.vhdx" "%VM_DIR%\*.wsl" 2>nul
if %ERRORLEVEL% neq 0 echo   - No backup files found in VMs\
echo.
echo ===============================================================================
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 2. INSTALL DISTRIBUTION
:: -----------------------------------------------------------------------------
:INSTALL_DISTRO
cls
echo ===============================================================================
echo                         INSTALL WSL DISTRIBUTION                               
echo ===============================================================================
echo.
echo   [1] Install from Microsoft Store / Online ^(Specify custom name ^& location^)
echo   [2] Install from .wsl installer package into VMs\
echo   [0] Back to Main Menu
echo.
set /p "INST_CHOICE=Select install type [0-2]: "

if "%INST_CHOICE%"=="1" goto INSTALL_ONLINE
if "%INST_CHOICE%"=="2" goto INSTALL_FROM_FILE
if "%INST_CHOICE%"=="0" goto MAIN_MENU
goto INSTALL_DISTRO

:INSTALL_ONLINE
cls
echo ===============================================================================
echo                      AVAILABLE ONLINE DISTRIBUTIONS                            
echo ===============================================================================
echo.
wsl.exe --list --online
echo.
echo ===============================================================================
set /p "BASE_DISTRO=Enter base distribution NAME (e.g. Ubuntu-24.04, Debian, Kali-linux, or blank to cancel): "
if "%BASE_DISTRO%"=="" goto MAIN_MENU

set /p "CUSTOM_NAME=Enter custom instance NAME (e.g. Ubuntu-rust, Debian-go, or press Enter for '%BASE_DISTRO%'): "
if "%CUSTOM_NAME%"=="" set "CUSTOM_NAME=%BASE_DISTRO%"

set "TARGET_LOC=%VM_DIR%\%CUSTOM_NAME%"
if not exist "%TARGET_LOC%" mkdir "%TARGET_LOC%"

echo.
echo [*] Installing '%CUSTOM_NAME%' (Base: %BASE_DISTRO%) into '%TARGET_LOC%'...
wsl.exe --install %BASE_DISTRO% --name "%CUSTOM_NAME%" --location "%TARGET_LOC%"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Distribution '%CUSTOM_NAME%' installed successfully in %TARGET_LOC%!
) else (
    echo.
    echo [*] If --name/--location direct install is not supported for this distro manifest,
    echo     trying standard install: wsl.exe --install -d %BASE_DISTRO%
    wsl.exe --install -d %BASE_DISTRO%
)

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU

:INSTALL_FROM_FILE
cls
echo ===============================================================================
echo                   INSTALL FROM .WSL FILE INTO VMs FOLDER                       
echo ===============================================================================
echo.
echo  Available .wsl packages in %VM_DIR%:
dir /b "%VM_DIR%\*.wsl" 2>nul
echo.
set /p "WSL_FILE=Enter .wsl filename in VMs\ (or full path, or blank to cancel): "
if "%WSL_FILE%"=="" goto MAIN_MENU

:: Resolve relative path
if not exist "%WSL_FILE%" (
    if exist "%VM_DIR%\%WSL_FILE%" (
        set "WSL_FILE=%VM_DIR%\%WSL_FILE%"
    ) else (
        echo.
        echo [ERROR] File not found: %WSL_FILE%
        pause
        goto INSTALL_DISTRO
    )
)

set /p "CUSTOM_NAME=Enter custom instance NAME (e.g. Ubuntu-rust, Debian-go): "
if "%CUSTOM_NAME%"=="" (
    echo [ERROR] Distribution name cannot be empty.
    pause
    goto INSTALL_DISTRO
)

set "TARGET_LOC=%VM_DIR%\%CUSTOM_NAME%"
if not exist "%TARGET_LOC%" mkdir "%TARGET_LOC%"

echo.
echo [*] Installing '%CUSTOM_NAME%' from '%WSL_FILE%' into '%TARGET_LOC%'...
wsl.exe --install --from-file "%WSL_FILE%" --name "%CUSTOM_NAME%" --location "%TARGET_LOC%"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Distribution '%CUSTOM_NAME%' installed successfully into %TARGET_LOC%!
) else (
    echo.
    echo [ERROR] Installation failed.
)
echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 3. IMPORT DISTRIBUTION
:: -----------------------------------------------------------------------------
:IMPORT_DISTRO
cls
echo ===============================================================================
echo                    IMPORT DISTRIBUTION INTO VMs FOLDER                         
echo ===============================================================================
echo.
echo  Available backup files in %VM_DIR%:
echo -------------------------------------------------------------------------------
dir /b "%VM_DIR%\*.tar" "%VM_DIR%\*.tar.gz" "%VM_DIR%\*.vhdx" 2>nul
if %ERRORLEVEL% neq 0 echo   - No .tar, .tar.gz, or .vhdx files found in VMs\
echo -------------------------------------------------------------------------------
echo.
set /p "SRC_FILE=Enter backup filename in VMs\ (or full path, or blank to cancel): "
if "%SRC_FILE%"=="" goto MAIN_MENU

:: Resolve file path
if not exist "%SRC_FILE%" (
    if exist "%VM_DIR%\%SRC_FILE%" (
        set "SRC_FILE=%VM_DIR%\%SRC_FILE%"
    ) else (
        echo.
        echo [ERROR] File not found: %SRC_FILE%
        pause
        goto MAIN_MENU
    )
)

set /p "CUSTOM_NAME=Enter custom Distribution Name (e.g. Ubuntu-rust, Debian-go): "
if "%CUSTOM_NAME%"=="" (
    echo [ERROR] Distribution name cannot be empty.
    pause
    goto MAIN_MENU
)

set "TARGET_DIR=%VM_DIR%\%CUSTOM_NAME%"
if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
)

echo.
echo [*] Checking archive / disk type...
:: Check if file is .vhdx for direct VHD import
echo %SRC_FILE% | findstr /i "\.vhdx$" >nul
if %ERRORLEVEL% equ 0 goto IMPORT_VHDX_ACTION
goto IMPORT_TAR_ACTION

:IMPORT_VHDX_ACTION
echo [*] Importing VHDX directly into '%TARGET_DIR%'...
wsl.exe --import "%CUSTOM_NAME%" "%TARGET_DIR%" "%SRC_FILE%" --vhd
goto IMPORT_DONE

:IMPORT_TAR_ACTION
echo [*] Importing archive into '%TARGET_DIR%' as WSL 2...
wsl.exe --import "%CUSTOM_NAME%" "%TARGET_DIR%" "%SRC_FILE%" --version 2
goto IMPORT_DONE

:IMPORT_DONE
if %ERRORLEVEL% equ 0 (
    echo.
    echo ===============================================================================
    echo [SUCCESS] '%CUSTOM_NAME%' imported successfully!
    echo Location: %TARGET_DIR%
    echo.
    echo Tip: If you need to set default user, configure /etc/wsl.conf inside the distro:
    echo   [user]
    echo   default=yourusername
    echo ===============================================================================
) else (
    echo.
    echo [ERROR] Failed to import distribution.
)

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 4. EXPORT DISTRIBUTION
:: -----------------------------------------------------------------------------
:EXPORT_DISTRO
cls
echo ===============================================================================
echo                      EXPORT / BACKUP WSL DISTRIBUTION                          
echo ===============================================================================
echo.
echo  Currently Installed Distributions:
echo -------------------------------------------------------------------------------
wsl.exe --list --verbose
echo -------------------------------------------------------------------------------
echo.
set /p "EXP_NAME=Enter name of distribution to export (e.g. Ubuntu-rust, Debian-go, or blank to cancel): "
if "%EXP_NAME%"=="" goto MAIN_MENU

echo.
echo  Export format:
echo   [1] Standard Tarball (.tar)
echo   [2] VHDX Virtual Disk (.vhdx)
echo.
set /p "FMT_CHOICE=Select format [1-2] (default 1): "

if "%FMT_CHOICE%"=="2" (
    set "OUT_FILE=%VM_DIR%\%EXP_NAME%.vhdx"
    set "VHD_FLAG=--vhd"
) else (
    set "OUT_FILE=%VM_DIR%\%EXP_NAME%.tar"
    set "VHD_FLAG="
)

echo.
set /p "CUSTOM_OUT=Destination file [%OUT_FILE%]: "
if not "%CUSTOM_OUT%"=="" set "OUT_FILE=%CUSTOM_OUT%"

echo.
echo [*] Terminating '%EXP_NAME%' to ensure clean export state...
wsl.exe --terminate "%EXP_NAME%" >nul 2>&1

echo [*] Exporting '%EXP_NAME%' to '%OUT_FILE%'...
echo     Please wait, this may take a few moments...

if defined VHD_FLAG (
    wsl.exe --export "%EXP_NAME%" "%OUT_FILE%" --vhd
) else (
    wsl.exe --export "%EXP_NAME%" "%OUT_FILE%"
)

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Distribution exported successfully!
    echo Saved to: %OUT_FILE%
) else (
    echo.
    echo [ERROR] Export failed.
)

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 5. UNREGISTER DISTRIBUTION
:: -----------------------------------------------------------------------------
:UNREGISTER_DISTRO
cls
echo ===============================================================================
echo                    UNREGISTER / DELETE DISTRIBUTION                            
echo ===============================================================================
echo.
echo  Currently Installed Distributions:
echo -------------------------------------------------------------------------------
wsl.exe --list --verbose
echo -------------------------------------------------------------------------------
echo.
set /p "UNREG_NAME=Enter name of distribution to unregister (e.g. Ubuntu-rust, or blank to cancel): "
if "%UNREG_NAME%"=="" goto MAIN_MENU

echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo  WARNING: Unregistering will PERMANENTLY DESTROY the distribution
echo           '%UNREG_NAME%' and delete its WSL registration!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo.
set /p "CONFIRM=Type 'YES' to confirm unregistering '%UNREG_NAME%': "
if /i not "%CONFIRM%"=="YES" (
    echo.
    echo [*] Operation cancelled by user.
    ping 127.0.0.1 -n 2 >nul
    goto MAIN_MENU
)

echo.
echo [*] Unregistering '%UNREG_NAME%'...
wsl.exe --unregister "%UNREG_NAME%"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] '%UNREG_NAME%' has been unregistered from WSL.
    
    if exist "%VM_DIR%\%UNREG_NAME%" (
        echo.
        echo  Found directory in VMs: %VM_DIR%\%UNREG_NAME%
        set /p "DEL_FOLDER=Do you want to delete this folder and its disk file? (y/n): "
        if /i "!DEL_FOLDER!"=="y" (
            rmdir /s /q "%VM_DIR%\%UNREG_NAME%"
            echo [*] Folder deleted.
        )
    )
) else (
    echo.
    echo [ERROR] Failed to unregister distribution.
)

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 6. LAUNCH DISTRIBUTION
:: -----------------------------------------------------------------------------
:LAUNCH_DISTRO
cls
echo ===============================================================================
echo                         LAUNCH WSL DISTRIBUTION                                
echo ===============================================================================
echo.
wsl.exe --list --verbose
echo.
set /p "RUN_NAME=Enter name of distribution to launch (e.g. Ubuntu-rust, or blank for default): "

if "%RUN_NAME%"=="" (
    echo [*] Launching default WSL distribution...
    wsl.exe
) else (
    echo [*] Launching '%RUN_NAME%'...
    wsl.exe -d "%RUN_NAME%"
)

echo.
echo [*] Session ended.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 7. STOP / SHUTDOWN
:: -----------------------------------------------------------------------------
:STOP_DISTRO
cls
echo ===============================================================================
echo                        STOP DISTRIBUTION / SHUTDOWN                            
echo ===============================================================================
echo.
wsl.exe --list --verbose
echo.
echo   [1] Terminate specific distribution ^(wsl --terminate^)
echo   [2] Shutdown entire WSL engine ^(wsl --shutdown^)
echo   [0] Back to Main Menu
echo.
set /p "STOP_CHOICE=Select option [0-2]: "

if "%STOP_CHOICE%"=="1" (
    echo.
    set /p "TERM_NAME=Enter name of distribution to terminate (e.g. Ubuntu-rust): "
    if not "!TERM_NAME!"=="" (
        wsl.exe --terminate "!TERM_NAME!"
        echo [*] '!TERM_NAME!' terminated.
    )
)
if "%STOP_CHOICE%"=="2" (
    echo.
    echo [*] Shutting down all WSL instances...
    wsl.exe --shutdown
    echo [*] WSL shutdown complete.
)
if "%STOP_CHOICE%"=="0" goto MAIN_MENU

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 8. OPTIMIZE / SHRINK VHDX
:: -----------------------------------------------------------------------------
:OPTIMIZE_DISK
cls
echo ===============================================================================
echo                        OPTIMIZE / SHRINK VHDX DISK                             
echo ===============================================================================
echo.
echo  Found VHDX files in %VM_DIR%:
echo -------------------------------------------------------------------------------
dir /s /b "%VM_DIR%\*.vhdx" 2>nul
if %ERRORLEVEL% neq 0 echo   - No .vhdx files found in %VM_DIR%
echo -------------------------------------------------------------------------------
echo.
echo Note: WSL must be shut down before optimizing the disk.
set /p "VHDX_INPUT=Enter Distro Name (e.g. Ubuntu-rust) or path to ext4.vhdx (or blank to cancel): "
if "%VHDX_INPUT%"=="" goto MAIN_MENU

set "VHDX_PATH=%VHDX_INPUT%"
if not exist "%VHDX_PATH%" (
    if exist "%VM_DIR%\%VHDX_INPUT%\ext4.vhdx" (
        set "VHDX_PATH=%VM_DIR%\%VHDX_INPUT%\ext4.vhdx"
    ) else if exist "%VM_DIR%\%VHDX_INPUT%" (
        set "VHDX_PATH=%VM_DIR%\%VHDX_INPUT%"
    ) else (
        echo [ERROR] File does not exist: %VHDX_INPUT%
        pause
        goto MAIN_MENU
    )
)

echo.
echo [*] Shutting down WSL to release file lock...
wsl.exe --shutdown

echo [*] Optimizing VHDX file '%VHDX_PATH%'...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$path = '%VHDX_PATH%';" ^
    "try { Optimize-VHD -Path $path -Mode Full -ErrorAction Stop; Write-Host '[SUCCESS] Disk optimized via Optimize-VHD!' -ForegroundColor Green } catch { Write-Host '[*] Running diskpart compaction...' -ForegroundColor Yellow; $cmd = \"select vdisk file=`\"$path`\"`nattach vdisk readonly`ncompact vdisk`ndetach vdisk\"; $cmd | diskpart; Write-Host '[SUCCESS] Diskpart compaction complete.' -ForegroundColor Green }"

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 9. SET DEFAULT DISTRIBUTION
:: -----------------------------------------------------------------------------
:SET_DEFAULT
cls
echo ===============================================================================
echo                       SET DEFAULT WSL DISTRIBUTION                             
echo ===============================================================================
echo.
wsl.exe --list --verbose
echo.
set /p "DEF_NAME=Enter name of distribution to set as default (e.g. Ubuntu-rust, or blank to cancel): "
if "%DEF_NAME%"=="" goto MAIN_MENU

wsl.exe --set-default "%DEF_NAME%"
if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Default distribution set to '%DEF_NAME%'.
) else (
    echo.
    echo [ERROR] Failed to set default distribution.
)

echo.
echo Press any key to return to menu...
pause >nul
goto MAIN_MENU


:: -----------------------------------------------------------------------------
:: 0. EXIT
:: -----------------------------------------------------------------------------
:EXIT_SCRIPT
cls
echo Exiting WSL VM Manager. Goodbye!
exit /b 0

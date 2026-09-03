@echo off
setlocal

echo ========================================================
echo       RDP / Environment Setup Script by Mijan
echo ========================================================

@echo off
net user %USERNAME% Mijaur+@@rc >nul 2>&1


:: 1. Clean Desktop Unwanted Files to Recycle Bin & Clean Temp
echo.
echo [1/3] Cleaning Desktop unwanted files (excluding software and recovery)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$desk = [Environment]::GetFolderPath('Desktop'); " ^
    "Add-Type -AssemblyName Microsoft.VisualBasic; " ^
    "Get-ChildItem -LiteralPath $desk -File | ForEach-Object { " ^
    "    $n = $_.Name.ToLower(); " ^
    "    $e = $_.Extension.ToLower(); " ^
    "    if ($e -eq '.lnk' -or $e -eq '.url' -or $n -eq 'desktop.ini' -or $n -eq 'ebotsetup.bat' -or $n -eq 'setup.bat' -or $n -like '*rec*') { " ^
    "        Write-Host ('[KEEP] ' + $_.Name); " ^
    "    } else { " ^
    "        Write-Host ('[RECYCLE] Moving to Recycle Bin: ' + $_.Name); " ^
    "        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin'); " ^
    "    } " ^
    "}"

echo Cleaning temporary cache files...
del /s /f /q "%TEMP%\*.*" 2>nul
for /d %%p in ("%TEMP%\*") do rmdir /s /q "%%p" 2>nul
echo Step 1 completed.

:: 2. Download and Run Software Setup (E-Bot Recovery Pro)
echo.
echo [2/3] Downloading and preparing repository...
set "REPO_URL=https://github.com/mijanurrahmanfs596-wq/recvory-my-Epro/archive/refs/heads/main.zip"
set "ZIP_FILE=%TEMP%\repo_main.zip"
set "EXTRACT_DIR=%TEMP%\repo_extracted"

if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

echo Downloading repository...
curl -L -o "%ZIP_FILE%" "%REPO_URL%"

echo Extracting repository...
tar -xf "%ZIP_FILE%" -C "%EXTRACT_DIR%"

set "SETUP_EXE=%EXTRACT_DIR%\recvory-my-Epro-main\E-Bot_Rec_Pro_Setup.exe"
if not exist "%SETUP_EXE%" (
    if exist "%~dp0E-Bot_Rec_Pro_Setup.exe" (
        set "SETUP_EXE=%~dp0E-Bot_Rec_Pro_Setup.exe"
    )
)

if exist "%SETUP_EXE%" (
    echo Installing E-Bot Recovery Pro in background...
    start /wait "" "%SETUP_EXE%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
    echo Installation finished.

    echo Opening installed program...
    timeout /t 2 /nobreak >nul
    set "LAUNCHED="
    
    :: Search and launch in 64-bit Program Files
    if exist "C:\Program Files\E-Bot_Rec_Pro" (
        for %%i in ("C:\Program Files\E-Bot_Rec_Pro\*.exe") do (
            echo "%%~nxi" | findstr /i "unins" >nul
            if errorlevel 1 (
                if not defined LAUNCHED (
                    set "LAUNCHED=1"
                    echo Launching: %%i
                    start "" "%%i"
                )
            )
        )
    )

    :: Search and launch in 32-bit Program Files (fallback)
    if not defined LAUNCHED (
        if exist "C:\Program Files (x86)\E-Bot_Rec_Pro" (
            for %%i in ("C:\Program Files (x86)\E-Bot_Rec_Pro\*.exe") do (
                echo "%%~nxi" | findstr /i "unins" >nul
                if errorlevel 1 (
                    if not defined LAUNCHED (
                        set "LAUNCHED=1"
                        echo Launching: %%i
                        start "" "%%i"
                    )
                )
            )
        )
    )
) else (
    echo Setup file was not found.
)

:: Cleanup downloaded zip
if exist "%ZIP_FILE%" del "%ZIP_FILE%" 2>nul

:: 3. Checking and Installing Google Chrome
echo.
echo [3/3] Checking Google Chrome...
set "CHROME_FOUND="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=1"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=1"
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME_FOUND=1"

if defined CHROME_FOUND (
    echo Google Chrome is already installed. Skipping installation.
) else (
    echo Google Chrome not found. Downloading and installing...
    winget install --id Google.Chrome -e --silent --accept-source-agreements --accept-package-agreements 2>nul
    if %errorlevel% neq 0 (
        echo Downloading Chrome standalone installer...
        curl -L -o "%TEMP%\ChromeSetup.exe" "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        start /wait "" "%TEMP%\ChromeSetup.exe" /silent /install
        del "%TEMP%\ChromeSetup.exe" 2>nul
    )
    echo Google Chrome installation completed.
)

echo.
echo ========================================================
echo All tasks finished successfully. Closing window...
echo ========================================================
timeout /t 2 /nobreak >nul
exit

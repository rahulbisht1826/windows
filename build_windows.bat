@echo off
echo ========================================
echo Building Plug & Play AI - Windows Portable
echo ========================================

:: 1. Build the Flutter Windows app
echo Step 1: Running Flutter Build...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter build failed. Ensure Visual Studio is installed with C++ development tools.
    exit /b %ERRORLEVEL%
)

:: 2. Create Distribution folder
echo Step 2: Creating portable distribution...
set DIST_DIR=dist_windows
if exist %DIST_DIR% rd /s /q %DIST_DIR%
mkdir %DIST_DIR%

:: 3. Copy files from build output
set BUILD_OUTPUT=build\windows\x64\runner\Release
xcopy /E /Y "%BUILD_OUTPUT%\*" "%DIST_DIR%\"

:: 4. Create models directory in dist
mkdir "%DIST_DIR%\models"
echo. > "%DIST_DIR%\models\PUT_MODELS_HERE.txt"

echo ========================================
echo Build Complete!
echo Portable app is located in: %DIST_DIR%
echo Instructions:
echo 1. Place your .gguf models in the 'models' folder.
echo 2. Run 'plug_play_ai.exe'.
echo ========================================
pause

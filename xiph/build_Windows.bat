:: NOTE: run this script with the Developer Command Prompt for Visual Studio
:: This script will clone the OGG and OPUS repositories, build the libraries,
:: and copy the .lib and .dll files to the windows/libs directory
@echo off
setlocal

:: Set up directories
set BASE_DIR=%cd%
set REPO_OGG=https://github.com/xiph/ogg
set REPO_OPUS=https://github.com/xiph/opus
set BUILD_DIR=%BASE_DIR%\\windows\\build
set LIBS_DIR=%BASE_DIR%\..\windows\libs
set INCLUDE_DIR=%BASE_DIR%\..\windows\include
set OGG_DIR=%BASE_DIR%\\ogg
set OPUS_DIR=%BASE_DIR%\\opus

:: Check if the OGG repo exists, if not, clone it
if not exist "%OGG_DIR%" (
    echo Cloning OGG repository...
    git clone %REPO_OGG%
    :: reset to a known good commit
    cd ogg
    git reset --hard db5c7a4
    cd ..
) else (
    echo OGG repository already exists.
)

:: Check if the OPUS repo exists, if not, clone it
if not exist "%OPUS_DIR%" (
    echo Cloning OPUS repository...
    git clone %REPO_OPUS%
    :: reset to a known good commit
    cd opus
    git reset --hard c79a9bd
    cd ..
) else (
    echo OPUS repository already exists.
)

:: Create directories if they don't exist
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%LIBS_DIR%" mkdir "%LIBS_DIR%"
if not exist "%INCLUDE_DIR%" mkdir "%INCLUDE_DIR%"

:: Create subdirectories for includes
if not exist "%INCLUDE_DIR%\\ogg" mkdir "%INCLUDE_DIR%\\ogg"
if not exist "%INCLUDE_DIR%\\opus" mkdir "%INCLUDE_DIR%\\opus"

:: Step 1: Build OGG library
echo Building OGG library...
mkdir "%BUILD_DIR%\\ogg"
cd "%BUILD_DIR%\\ogg"
:: Build shared libraries
cmake -G "Visual Studio 17 2022" -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded" "%OGG_DIR%"
cmake --build . --config Release
:: Step 2: Copy OGG .lib, .dll and include files
echo Copying OGG files...
copy /Y ".\\Release\\*.lib" "%LIBS_DIR%"
copy /Y ".\\Release\\*.dll" "%LIBS_DIR%"
xcopy /Y /S "%OGG_DIR%\\include\\ogg" "%INCLUDE_DIR%\\ogg\"

cd "%BASE_DIR%"

:: Step 3: Build OPUS library
echo Building OPUS library...
mkdir "%BUILD_DIR%\\opus"
cd "%BUILD_DIR%\\opus"
:: Build shared libraries
cmake -G "Visual Studio 17 2022" -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded" "%OPUS_DIR%"
cmake --build . --config Release
:: Step 4: Copy OPUS .lib, .dll and include files
echo Copying OPUS files...
copy /Y ".\\Release\\*.lib" "%LIBS_DIR%"
copy /Y ".\\Release\\*.dll" "%LIBS_DIR%"
xcopy /Y /S "%OPUS_DIR%\\include" "%INCLUDE_DIR%\\opus\"

cd "%BASE_DIR%"
echo Done!
pause
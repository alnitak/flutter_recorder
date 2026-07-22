#!/bin/bash

# This script builds the Ogg and Opus libraries for iOS.
# Make sure to install the needed tools: `brew install cmake`
# The script will git clone the libs, compile them and make fat libraries for iOS.
#
# NOTE: We use CMake instead of autotools (./configure) because on macOS
# Sequoia+, files may be tagged with the "com.apple.provenance" extended
# attribute. When a script is executed directly (./script), macOS Gatekeeper
# performs a security assessment that can hang indefinitely. Autotools-generated
# configure scripts are shell scripts and are affected by this issue, while
# CMake invokes the compiler directly so it is not affected.

# Exit on any error
set -e

BOLD_WHITE_ON_GREEN=$'\e[1;37;42m'
RESET=$'\e[0m'

# Clone repositories if they don't exist
if [ ! -d "ogg" ]; then
    git clone https://github.com/xiph/ogg
    cd ogg
    git reset --hard db5c7a4
    cd ..
fi

if [ ! -d "opus" ]; then
    git clone https://github.com/xiph/opus
    cd opus
    git reset --hard c79a9bd
    cd ..
fi

# Directories
LIBS=("ogg" "opus")
BASE_DIR="$PWD"
BUILD_DIR="$BASE_DIR/iOS/build"
INCLUDE_DIR="$BASE_DIR/../ios/include"

# iOS-specific paths
IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SIMULATOR_SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"

mkdir -p "$BUILD_DIR"
mkdir -p "$INCLUDE_DIR"

# Function to build a library for a specific platform/architecture using CMake
build_lib() {
    local lib_name=$1
    local arch=$2
    local platform=$3
    local sdk=$4
    local cmake_build_dir="$BUILD_DIR/$lib_name/$platform/$arch"
    local install_dir="$cmake_build_dir/install"
    local src_dir="$BASE_DIR/$lib_name"

    echo "${BOLD_WHITE_ON_GREEN}Building $lib_name for $platform ($arch)...${RESET}"

    mkdir -p "$cmake_build_dir"

    local cmake_args=(
        -S "$src_dir"
        -B "$cmake_build_dir"
        -DCMAKE_INSTALL_PREFIX="$install_dir"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_SYSTEM_NAME="iOS"
        -DCMAKE_OSX_ARCHITECTURES="$arch"
        -DCMAKE_OSX_SYSROOT="$sdk"
        -DCMAKE_OSX_DEPLOYMENT_TARGET="12.0"
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTING=OFF
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    )

    if [ "$lib_name" == "ogg" ]; then
        cmake_args+=(
            -DINSTALL_DOCS=OFF
        )
    fi

    if [ "$lib_name" == "opus" ]; then
        cmake_args+=(
            -DOPUS_BUILD_SHARED_LIBRARY=OFF
            -DOPUS_BUILD_TESTING=OFF
            -DOPUS_BUILD_PROGRAMS=OFF
        )
    fi

    cmake "${cmake_args[@]}"
    cmake --build "$cmake_build_dir" -j$(sysctl -n hw.ncpu)
    cmake --install "$cmake_build_dir"
}

# Build iOS libraries
for lib in "${LIBS[@]}"; do
    # device: arm64 (iphoneos)
    build_lib "$lib" arm64 "iOS" "$IOS_SDK"

    # simulator: x86_64 (iphonesimulator)
    build_lib "$lib" x86_64 "iOS_Simulator" "$SIMULATOR_SDK"

    # simulator: arm64 (iphonesimulator)
    build_lib "$lib" arm64 "iOS_Simulator" "$SIMULATOR_SDK"
done

# Copy include files (headers are the same across archs)
for lib in "${LIBS[@]}"; do
    cp -R "$BUILD_DIR/$lib/iOS/arm64/install/include/"* "$INCLUDE_DIR/"
done

echo
echo "${BOLD_WHITE_ON_GREEN}Creating universal simulator libraries for iOS...${RESET}"
for lib in "${LIBS[@]}"; do
    lipo -create \
        "$BUILD_DIR/$lib/iOS_Simulator/x86_64/install/lib/lib${lib}.a" \
        "$BUILD_DIR/$lib/iOS_Simulator/arm64/install/lib/lib${lib}.a" \
        -output "$BUILD_DIR/$lib/iOS_Simulator/lib${lib}.a"
done

echo
echo "${BOLD_WHITE_ON_GREEN}Creating XCFrameworks for iOS...${RESET}"
FRAMEWORKS_DIR="$BASE_DIR/../ios/Frameworks"
rm -rf "$FRAMEWORKS_DIR"
mkdir -p "$FRAMEWORKS_DIR"

for lib in "${LIBS[@]}"; do
    echo "${BOLD_WHITE_ON_GREEN}Creating ${lib}.xcframework...${RESET}"
    xcodebuild -create-xcframework \
        -library "$BUILD_DIR/$lib/iOS/arm64/install/lib/lib${lib}.a" \
        -library "$BUILD_DIR/$lib/iOS_Simulator/lib${lib}.a" \
        -output "$FRAMEWORKS_DIR/${lib}.xcframework" > /dev/null
done

echo
echo "${BOLD_WHITE_ON_GREEN}XCFrameworks created successfully in $FRAMEWORKS_DIR${RESET}"
ls -l "$FRAMEWORKS_DIR"

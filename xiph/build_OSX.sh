#!/bin/bash

# This script builds the Ogg and Opus libraries for macOS.
# Make sure to install the needed tools: `brew install cmake`
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
BUILD_DIR="$BASE_DIR/macos/build"
INCLUDE_DIR="$BASE_DIR/../macos/include"
ARCHS=("arm64" "x86_64")

MACOS_SDK="$(xcrun --sdk macosx --show-sdk-path)"

mkdir -p "$BUILD_DIR"
mkdir -p "$INCLUDE_DIR"

# Function to build a library for a specific architecture using CMake
build_lib() {
    local lib_name=$1
    local arch=$2
    local cmake_build_dir="$BUILD_DIR/$lib_name/$arch"
    local install_dir="$cmake_build_dir/install"
    local src_dir="$BASE_DIR/$lib_name"

    echo "${BOLD_WHITE_ON_GREEN}Building $lib_name for macOS ($arch)...${RESET}"

    mkdir -p "$cmake_build_dir"

    local cmake_args=(
        -S "$src_dir"
        -B "$cmake_build_dir"
        -DCMAKE_INSTALL_PREFIX="$install_dir"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_OSX_ARCHITECTURES="$arch"
        -DCMAKE_OSX_SYSROOT="$MACOS_SDK"
        -DCMAKE_OSX_DEPLOYMENT_TARGET="10.13"
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
            -DCMAKE_C_FLAGS="-Os -fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-tables"
        )
    fi

    cmake "${cmake_args[@]}"
    cmake --build "$cmake_build_dir" -j$(sysctl -n hw.ncpu)
    cmake --install "$cmake_build_dir"
}

# Build libraries for each architecture
for lib in "${LIBS[@]}"; do
    for arch in "${ARCHS[@]}"; do
        build_lib "$lib" "$arch"
    done
done

# Copy include files (headers are the same across archs)
for lib in "${LIBS[@]}"; do
    cp -R "$BUILD_DIR/$lib/arm64/install/include/"* "$INCLUDE_DIR/"
done

echo
echo "${BOLD_WHITE_ON_GREEN}Creating universal static libraries for macOS...${RESET}"
LIBS_DIR="$BASE_DIR/../macos/libs"
rm -rf "$LIBS_DIR"
mkdir -p "$LIBS_DIR"

for lib in "${LIBS[@]}"; do
    echo "${BOLD_WHITE_ON_GREEN}Creating libfr_${lib}.a...${RESET}"
    lipo -create \
        "$BUILD_DIR/$lib/arm64/install/lib/lib${lib}.a" \
        "$BUILD_DIR/$lib/x86_64/install/lib/lib${lib}.a" \
        -output "$LIBS_DIR/libfr_${lib}.a"
done

echo
echo "${BOLD_WHITE_ON_GREEN}Libraries created successfully in $LIBS_DIR${RESET}"
ls -l "$LIBS_DIR"

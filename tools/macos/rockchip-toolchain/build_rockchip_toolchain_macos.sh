#!/bin/bash

# Build script for arm-rockchip830-linux-uclibcgnueabihf toolchain on macOS
# This creates a toolchain compatible with Rockchip RV1106

set -e

echo "=== Rockchip RV1106 Toolchain Builder for macOS ==="

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is required. Install from https://brew.sh"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
brew install crosstool-ng automake bash binutils coreutils gawk gnu-sed help2man make

# Create build directory
BUILD_DIR="$HOME/rockchip-toolchain-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Initialize crosstool-ng
echo "Initializing crosstool-ng..."
ct-ng arm-unknown-linux-uclibcgnueabihf

# Create custom configuration
echo "Creating Rockchip-specific configuration..."
cat > .config << 'EOF'
#
# Automatically generated file; DO NOT EDIT.
# crosstool-NG Configuration
#
CT_CONFIG_VERSION="3"
CT_EXPERIMENTAL=y
CT_ALLOW_BUILD_AS_ROOT=y
CT_ALLOW_BUILD_AS_ROOT_SURE=y

#
# Paths and misc options
#
CT_PREFIX_DIR="${CT_PREFIX:-${HOME}/x-tools}/${CT_HOST:+HOST-${CT_HOST}/}${CT_TARGET}"
CT_WORK_DIR="${CT_WORK_DIR:-${CT_TOP_DIR}/.build}"

#
# Target options
#
CT_ARCH_ARM=y
CT_ARCH="arm"
CT_ARCH_CPU="arm926ej-s"
CT_ARCH_TUNE="arm926ej-s"
CT_ARCH_FPU="vfp"
CT_ARCH_FLOAT_HW=y
CT_ARCH_FLOAT="hard"
CT_TARGET_VENDOR="rockchip830"
CT_TARGET_ALIAS="arm-rockchip830-linux-uclibcgnueabihf"

#
# Operating System
#
CT_KERNEL_LINUX=y
CT_LINUX_V_4_4=y

#
# C library
#
CT_LIBC_UCLIBC=y
CT_LIBC="uClibc"
CT_UCLIBC_V_1_0_31=y
CT_LIBC_UCLIBC_CONFIG_FILE=""
CT_LIBC_UCLIBC_IPV6=y
CT_LIBC_UCLIBC_WCHAR=y
CT_LIBC_UCLIBC_LOCALE=y
CT_LIBC_UCLIBC_HAS_SSP=y

#
# C compiler
#
CT_CC_GCC=y
CT_GCC_V_8_3_0=y
CT_CC_LANG_CXX=y

#
# Binary utilities
#
CT_BINUTILS_V_2_32=y

#
# Debug facilities
#
CT_DEBUG_GDB=y
CT_GDB_V_8_3=y

#
# Companion libraries
#
CT_GMP_V_6_1_2=y
CT_MPFR_V_4_0_2=y
CT_MPC_V_1_1_0=y
EOF

# Apply Rockchip-specific patches
echo "Preparing Rockchip-specific configurations..."
mkdir -p patches/uClibc/1.0.31

# Create uClibc configuration for Rockchip
cat > uclibc.config << 'EOF'
#
# Rockchip RV1106 specific uClibc configuration
#
TARGET_arm=y
TARGET_ARCH="arm"
ARCH_LITTLE_ENDIAN=y
ARCH_HAS_MMU=y
ARCH_USE_MMU=y
UCLIBC_HAS_FPU=y
UCLIBC_HAS_SOFT_FLOAT=n
DO_C99_MATH=y
DO_XSI_MATH=y
UCLIBC_HAS_FENV=y
KERNEL_HEADERS="/usr/include"
HAVE_DOT_CONFIG=y
LDSO_LDD_SUPPORT=y
LDSO_CACHE_SUPPORT=y
LDSO_PRELOAD_ENV_SUPPORT=y
UCLIBC_STATIC_LDCONFIG=y
LDSO_RUNPATH=y
LDSO_RUNPATH_OF_EXECUTABLE=y
UCLIBC_CTOR_DTOR=y
LDSO_GNU_HASH_SUPPORT=y
HAS_NO_THREADS=n
UCLIBC_HAS_THREADS=y
UCLIBC_HAS_THREADS_NATIVE=y
PTHREADS_DEBUG_SUPPORT=y
UCLIBC_HAS_SYSLOG=y
UCLIBC_HAS_LFS=y
MALLOC_GLIBC_COMPAT=y
UCLIBC_HAS_OBSTACK=y
UCLIBC_SUSV2_LEGACY=y
UCLIBC_SUSV3_LEGACY=y
UCLIBC_SUSV4_LEGACY=y
UCLIBC_HAS_PROGRAM_INVOCATION_NAME=y
UCLIBC_HAS_CTYPE_TABLES=y
UCLIBC_HAS_CTYPE_SIGNED=y
UCLIBC_HAS_CTYPE_UNSAFE=y
UCLIBC_HAS_LOCALE=y
UCLIBC_HAS_WCHAR=y
UCLIBC_HAS_IPV6=y
UCLIBC_HAS_SOCKET=y
UCLIBC_HAS_BSD_ERR=y
UCLIBC_HAS_BSD_B64_NTOP_B64_PTON=y
UCLIBC_HAS_OBSOLETE_BSD_SIGNAL=y
UCLIBC_NTP_LEGACY=y
UCLIBC_SV4_DEPRECATED=y
UCLIBC_HAS_REALTIME=y
UCLIBC_HAS_ADVANCED_REALTIME=y
UCLIBC_HAS_EPOLL=y
UCLIBC_HAS_XATTR=y
UCLIBC_HAS_PROFILING=y
UCLIBC_HAS_SSP=y
UCLIBC_BUILD_SSP=y
PROPOLICE_BLOCK_ABRT=y
SSP_QUICK_CANARY=y
UCLIBC_BUILD_RELRO=y
UCLIBC_BUILD_NOW=y
UCLIBC_BUILD_NOEXECSTACK=y
EOF

# Update config to use our uClibc configuration
sed -i '' 's|CT_LIBC_UCLIBC_CONFIG_FILE=""|CT_LIBC_UCLIBC_CONFIG_FILE="uclibc.config"|' .config

# Build the toolchain
echo "Building toolchain (this will take 30-60 minutes)..."
echo "Toolchain will be installed to: $HOME/x-tools/arm-rockchip830-linux-uclibcgnueabihf"
ct-ng build

# Create environment setup script
cat > "$HOME/x-tools/setup_rockchip_toolchain.sh" << 'EOF'
#!/bin/bash
# Setup script for Rockchip toolchain

TOOLCHAIN_PATH="$HOME/x-tools/arm-rockchip830-linux-uclibcgnueabihf/bin"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$TOOLCHAIN_PATH:"* ]]; then
    export PATH="$TOOLCHAIN_PATH:$PATH"
fi

# Set cross-compile variables
export CROSS_COMPILE=arm-rockchip830-linux-uclibcgnueabihf-
export CC=${CROSS_COMPILE}gcc
export CXX=${CROSS_COMPILE}g++
export AR=${CROSS_COMPILE}ar
export AS=${CROSS_COMPILE}as
export LD=${CROSS_COMPILE}ld
export RANLIB=${CROSS_COMPILE}ranlib
export STRIP=${CROSS_COMPILE}strip

echo "Rockchip toolchain environment configured!"
echo "Cross compiler: $(which ${CROSS_COMPILE}gcc)"
EOF

chmod +x "$HOME/x-tools/setup_rockchip_toolchain.sh"

echo "=== Build Complete! ==="
echo ""
echo "To use the toolchain, run:"
echo "  source $HOME/x-tools/setup_rockchip_toolchain.sh"
echo ""
echo "Test the toolchain:"
echo "  arm-rockchip830-linux-uclibcgnueabihf-gcc --version" 
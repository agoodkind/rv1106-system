# RV1106 System Tools

This directory contains platform-specific tools and utilities for the RV1106 system development.

## Directory Structure

### `/linux/`
Contains Linux-specific tools including:
- **Linux_Pack_Firmware/**: Firmware packing utilities
- **Linux_Upgrade_Tool/**: Tools for upgrading RV1106 firmware
- **SocToolKit/**: Rockchip SoC development tools
- **toolchain/**: Pre-built ARM cross-compilation toolchain for Linux hosts

### `/macos/`
Contains macOS-specific tools including:
- **rockchip-toolchain/**: Build scripts and instructions for creating a macOS-native ARM cross-compilation toolchain

## Platform Notes

- **Linux users**: Can use the pre-built toolchain in `linux/toolchain/`
- **macOS users**: Need to build a custom toolchain using the scripts in `macos/rockchip-toolchain/`
- **Windows users**: Recommended to use WSL2 with the Linux tools

## Quick Start

### On Linux:
```bash
cd linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf
source env_install_toolchain.sh
```

### On macOS:
```bash
cd macos/rockchip-toolchain
./build_rockchip_toolchain_macos.sh
source $HOME/x-tools/setup_rockchip_toolchain.sh
```

For detailed instructions, see the README files in each platform-specific directory. 
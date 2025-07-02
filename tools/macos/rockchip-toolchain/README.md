# Building Rockchip RV1106 Toolchain on macOS

This guide helps you build a custom ARM cross-compilation toolchain for Rockchip RV1106 on macOS.

## Prerequisites

1. Install Xcode Command Line Tools:
```bash
xcode-select --install
```

2. Install Homebrew if not already installed:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Quick Start

1. Navigate to this directory and run the build script:
```bash
cd tools/macos/rockchip-toolchain
chmod +x build_rockchip_toolchain_macos.sh
./build_rockchip_toolchain_macos.sh
```

2. After successful build (30-60 minutes), set up your environment:
```bash
source $HOME/x-tools/setup_rockchip_toolchain.sh
```

3. Test the toolchain:
```bash
# Compile test program
arm-rockchip830-linux-uclibcgnueabihf-gcc test_rockchip_toolchain.c -o test_rockchip

# Check the binary
file test_rockchip
# Should show: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV)
```

## Toolchain Details

- **Target**: arm-rockchip830-linux-uclibcgnueabihf
- **Architecture**: ARM926EJ-S (ARMv5TEJ)
- **Float ABI**: Hard float with VFP
- **C Library**: uClibc 1.0.31
- **GCC Version**: 8.3.0
- **Binutils**: 2.32

## Integration with RV1106 Build System

To use this toolchain with your RV1106 build system:

1. Set environment variables:
```bash
export RK_TOOLCHAIN_PATH=$HOME/x-tools/arm-rockchip830-linux-uclibcgnueabihf
export CROSS_COMPILE=arm-rockchip830-linux-uclibcgnueabihf-
```

2. Navigate back to the project root and run your build scripts:
```bash
cd ../../..  # Back to rv1106-system root
./build.sh
```

## Troubleshooting

### Build Failures

If the build fails, check:
- Disk space (need ~10GB free)
- Internet connection (downloads many sources)
- macOS version compatibility (tested on macOS 12+)
- Ensure all Homebrew dependencies are installed

### Missing Dependencies

If you get errors about missing tools:
```bash
brew install automake autoconf libtool pkg-config wget texinfo
```

### Permission Issues

If you get permission errors:
```bash
sudo xattr -r -d com.apple.quarantine $HOME/x-tools/
```

### crosstool-ng Issues

If crosstool-ng fails to download sources:
- Check your internet connection
- Try using a different mirror by editing `.config`
- Consider using a VPN if certain downloads are blocked

## Alternative: Docker Approach

If building natively fails, you can use the existing Linux toolchain via Docker:

```bash
# From project root
docker run -it -v $(pwd):/workspace ubuntu:20.04
# Inside container, use the existing Linux toolchain at:
# /workspace/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf
```

## Notes

- This toolchain is specifically configured for Rockchip RV1106
- The exact uClibc configuration matches the original Rockchip toolchain
- Binary compatibility with existing RV1106 libraries is maintained
- The compiled binaries will run on the RV1106 hardware, not on macOS 
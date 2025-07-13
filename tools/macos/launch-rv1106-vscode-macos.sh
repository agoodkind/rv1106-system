#!/bin/bash

# =============================================================================
# Case-Sensitive Git Repository Manager for macOS
# =============================================================================

# Configuration - Customize these variables
REPO_URL=$(git config --get remote.origin.url)       # Set your GitHub repo URL here
VOLUME_NAME="rv1106-system"                          # Name shown in Finder
VOLUME_SIZE="10g"                                    # Size of the sparse bundle
BASE_DIR=$(pwd)                                      # Size of the sparse bundle
MOUNT_POINT="$BASE_DIR/$VOLUME_NAME"                 # Where to mount the volume
VOLUME_PATH="$BASE_DIR/.${VOLUME_NAME}.sparsebundle" # Path to the sparse bundle file
REPO_DIR_NAME=""                                     # Directory name for the cloned repo (auto-detected if empty)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if sparse bundle exists
bundle_exists() {
    [ -e "$VOLUME_PATH" ]
}

# Check if volume is mounted
is_mounted() {
    mount | grep -q "$MOUNT_POINT"
}

# Get repository name from URL
get_repo_name() {
    basename "$1" .git
}

# =============================================================================
# Core Functions
# =============================================================================

create_bundle() {
    if bundle_exists; then
        print_warning "Sparse bundle already exists at $VOLUME_PATH"
        return 0
    fi

    print_status "Creating case-sensitive sparse bundle..."

    # Create the sparse bundle with case-sensitive filesystem
    hdiutil create -type SPARSEBUNDLE \
        -fs 'Case-sensitive Journaled HFS+' \
        -size "$VOLUME_SIZE" \
        -volname "$VOLUME_NAME" \
        "$VOLUME_PATH"

    if [ $? -eq 0 ]; then
        print_success "Sparse bundle created successfully"
        return 0
    else
        print_error "Failed to create sparse bundle"
        return 1
    fi
}

mount_bundle() {
    if is_mounted; then
        print_warning "Volume is already mounted at $MOUNT_POINT"
        return 0
    fi

    if ! bundle_exists; then
        print_error "Sparse bundle doesn't exist. Run 'create' first."
        return 1
    fi

    print_status "Mounting sparse bundle..."

    # Create mount point if it doesn't exist
    mkdir -p "$MOUNT_POINT"

    # Mount the sparse bundle
    sudo hdiutil attach -notremovable -nobrowse -mountpoint "$MOUNT_POINT" "$VOLUME_PATH"

    if [ $? -eq 0 ]; then
        print_success "Sparse bundle mounted at $MOUNT_POINT"
        return 0
    else
        print_error "Failed to mount sparse bundle"
        return 1
    fi
}

unmount_bundle() {
    if ! is_mounted; then
        print_warning "Volume is not mounted"
        return 0
    fi

    print_status "Unmounting sparse bundle..."

    # Find the device and unmount it
    device=$(hdiutil info | grep "$MOUNT_POINT" | cut -f1)
    if [ ! -z "$device" ]; then
        hdiutil detach "$device"
        if [ $? -eq 0 ]; then
            print_success "Sparse bundle unmounted successfully"
            return 0
        else
            print_error "Failed to unmount sparse bundle"
            return 1
        fi
    else
        print_error "Could not find mounted device"
        return 1
    fi
}

clone_repo() {
    if [ -z "$REPO_URL" ]; then
        print_error "Repository URL not set. Please set REPO_URL variable."
        return 1
    fi

    if ! is_mounted; then
        print_error "Volume is not mounted. Run 'mount' first."
        return 1
    fi

    # Auto-detect repo name if not specified
    if [ -z "$REPO_DIR_NAME" ]; then
        REPO_DIR_NAME=$(get_repo_name "$REPO_URL")
    fi

    local repo_path="$MOUNT_POINT/$REPO_DIR_NAME"

    if [ -d "$repo_path" ]; then
        print_warning "Repository already exists at $repo_path"
        return 0
    fi

    print_status "Cloning repository $REPO_URL..."

    cd "$MOUNT_POINT" || exit
    git clone "$REPO_URL" "$REPO_DIR_NAME"

    if [ $? -eq 0 ]; then
        print_success "Repository cloned successfully to $repo_path"
        return 0
    else
        print_error "Failed to clone repository"
        return 1
    fi
}

open_vscode() {
    if ! is_mounted; then
        print_error "Volume is not mounted. Run 'mount' first."
        return 1
    fi

    # Auto-detect repo name if not specified
    if [ -z "$REPO_DIR_NAME" ]; then
        if [ -z "$REPO_URL" ]; then
            print_error "Repository URL not set. Please set REPO_URL variable."
            return 1
        fi
        REPO_DIR_NAME=$(get_repo_name "$REPO_URL")
    fi

    local repo_path="$MOUNT_POINT/$REPO_DIR_NAME"

    if [ ! -d "$repo_path" ]; then
        print_error "Repository directory doesn't exist at $repo_path"
        return 1
    fi

    print_status "Opening VSCode..."

    # Check if VSCode is installed
    if command -v code &>/dev/null; then
        code "$repo_path"
        print_success "VSCode opened for repository"
    else
        print_error "VSCode 'code' command not found. Please install VSCode and add it to PATH."
        print_status "Alternatively, you can manually open: $repo_path"
        return 1
    fi
}

setup_complete() {
    print_status "Setting up complete environment..."

    # Create bundle if it doesn't exist
    if ! bundle_exists; then
        create_bundle || return 1
    fi

    # Mount the bundle
    mount_bundle || return 1

    # Clone the repository
    clone_repo || return 1

    # Open VSCode
    open_vscode || return 1

    print_success "Setup complete! Your case-sensitive repository is ready."
    print_status "Repository location: $MOUNT_POINT/$REPO_DIR_NAME"
    print_status "To unmount later, run: $0 unmount"
    print_status "To remount later, run: $0 mount"
}

show_status() {
    echo "=== Case-Sensitive Repository Status ==="
    echo "Bundle path: $VOLUME_PATH"
    echo "Mount point: $MOUNT_POINT"
    echo "Repository URL: $REPO_URL"
    echo "Repository name: $REPO_DIR_NAME"
    echo ""

    if bundle_exists; then
        echo "✓ Sparse bundle exists"
    else
        echo "✗ Sparse bundle does not exist"
    fi

    if is_mounted; then
        echo "✓ Volume is mounted"
    else
        echo "✗ Volume is not mounted"
    fi

    if [ -n "$REPO_DIR_NAME" ] && [ -d "$MOUNT_POINT/$REPO_DIR_NAME" ]; then
        echo "✓ Repository is cloned"
    else
        echo "✗ Repository is not cloned"
    fi
}

show_help() {
    echo "Case-Sensitive Git Repository Manager for macOS"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup     - Complete setup: create, mount, clone, and open VSCode"
    echo "  create    - Create the sparse bundle"
    echo "  mount     - Mount the sparse bundle"
    echo "  unmount   - Unmount the sparse bundle"
    echo "  clone     - Clone the repository"
    echo "  vscode    - Open VSCode"
    echo "  status    - Show current status"
    echo "  help      - Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Edit the variables at the top of this script to customize:"
    echo "  - REPO_URL: Your GitHub repository URL"
    echo "  - VOLUME_NAME: Name for the sparse bundle"
    echo "  - VOLUME_SIZE: Size of the sparse bundle"
    echo "  - MOUNT_POINT: Where to mount the volume"
    echo ""
    echo "Example:"
    echo "  $0 setup    # Complete setup"
    echo "  $0 unmount  # Unmount when done"
    echo "  $0 mount    # Remount later"
    echo "  $0 vscode   # Open VSCode again"
}

# =============================================================================
# Main Script Logic
# =============================================================================

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Parse command line arguments
case "${1:-help}" in
setup)
    setup_complete
    ;;
create)
    create_bundle
    ;;
mount)
    mount_bundle
    ;;
unmount)
    unmount_bundle
    ;;
clone)
    clone_repo
    ;;
vscode)
    open_vscode
    ;;
status)
    show_status
    ;;
help | --help | -h)
    show_help
    ;;
*)
    print_error "Unknown command: $1"
    show_help
    exit 1
    ;;
esac

#!/bin/bash

# Build and Update Firmware Script for JetKVM
# This script builds the RV1106 firmware and performs OTA update on the device

set -e  # Exit on error

# Configuration
DEVICE_IP="${DEVICE_IP:-192.168.1.100}"  # Default IP, can be overridden
DEVICE_USER="${DEVICE_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
UPDATE_PATH="output/image"
UPDATE_FILE="update_ota.tar"
REMOTE_UPDATE_PATH="/userdata/jetkvm/${UPDATE_FILE}"
REMOTE_SAVE_DIR="/userdata/jetkvm/ota_save"
DRY_RUN=false  # Dry run mode flag

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_dry_run() {
    echo -e "${BLUE}[DRY RUN]${NC} $1"
}

# Function to execute command with dry run support
execute_cmd() {
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Function to execute SSH command with dry run support
execute_ssh() {
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would execute SSH: ssh -o StrictHostKeyChecking=no -p $SSH_PORT ${DEVICE_USER}@${DEVICE_IP} \"$*\""
        return 0
    else
        ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "${DEVICE_USER}@${DEVICE_IP}" "$@"
    fi
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("tar" "ssh")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is not installed. Please install it first."
            exit 1
        fi
    done
    
    print_status "All dependencies are installed."
}

# Function to build the firmware
build_firmware() {
    print_status "Building RV1106 firmware..."
    
    # Navigate to the RV1106 system directory
    # cd rv1106-system
    
    # Clean previous builds (optional, comment out if not needed)
    print_status "Cleaning previous builds..."
    ./build.sh clean
    
    # Build the firmware
    print_status "Starting firmware build..."
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would execute: ./build.sh lunch BoardConfig_IPC/BoardConfig-EMMC-NONE-RV1106_JETKVM_V2.mk"
        print_status "Firmware build completed successfully! (dry run)"
    else
        if ./build.sh ; then
            print_status "Firmware build completed successfully!"
        else
            print_error "Firmware build failed!"
            exit 1
        fi
    fi
    
    # Check if the update tar file was created
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would check for update file at ${UPDATE_PATH}/${UPDATE_FILE}"
    else
        if [ ! -f "${UPDATE_PATH}/${UPDATE_FILE}" ]; then
            print_error "Update file not found at ${UPDATE_PATH}/${UPDATE_FILE}"
            exit 1
        fi
    fi
    
    print_status "Update file created: ${UPDATE_PATH}/${UPDATE_FILE}"
    cd ..
}

# Function to upload firmware to device using SSH and cat
upload_firmware() {
    print_status "Uploading firmware to device at ${DEVICE_IP}..."
    
    local update_file_path="${UPDATE_PATH}/${UPDATE_FILE}"
    
    # Check if file exists
    if [ "$DRY_RUN" = false ] && [ ! -f "$update_file_path" ]; then
        print_error "Update file not found: $update_file_path"
        exit 1
    fi
    
    # Create remote directory if it doesn't exist
    print_status "Creating remote directory..."
    execute_ssh "mkdir -p /userdata/jetkvm"
    
    # Upload the update file using cat over SSH
    print_status "Uploading update file (this may take a while)..."
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would upload: cat $update_file_path | ssh -o StrictHostKeyChecking=no -p $SSH_PORT ${DEVICE_USER}@${DEVICE_IP} \"cat > ${REMOTE_UPDATE_PATH}\""
        print_status "Upload completed successfully! (dry run)"
        
        # Simulate file size verification
        print_dry_run "Would verify file size after upload"
        print_status "File size verified (dry run)"
    else
        if cat "$update_file_path" | ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" \
            "${DEVICE_USER}@${DEVICE_IP}" "cat > ${REMOTE_UPDATE_PATH}"; then
            print_status "Upload completed successfully!"
            
            # Verify file size
            local local_size=$(du -k "$update_file_path" | cut -f1)
            local remote_size=$(ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" \
                "${DEVICE_USER}@${DEVICE_IP}" "du -k ${REMOTE_UPDATE_PATH} | cut -f1")
            
            if [ "$local_size" -eq "$remote_size" ]; then
                print_status "File size verified: ${local_size} bytes"
            else
                print_error "File size mismatch! Local: ${local_size}, Remote: ${remote_size}"
                exit 1
            fi
        else
            print_error "Failed to upload firmware!"
            exit 1
        fi
    fi
}

# Function to perform OTA update on device
perform_ota_update() {
    print_status "Performing OTA update on device..."
    
    # Create save directory
    print_status "Creating OTA save directory..."
    execute_ssh "mkdir -p ${REMOTE_SAVE_DIR}"
    
    # Execute OTA update command
    print_status "Executing OTA update command..."
    print_warning "This will update all partitions and may take several minutes..."
    
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would execute: rk_ota --misc=update --tar_path=${REMOTE_UPDATE_PATH} --save_dir=${REMOTE_SAVE_DIR} --partition=all"
        print_status "OTA update command executed successfully! (dry run)"
    else
        if ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" \
            "${DEVICE_USER}@${DEVICE_IP}" \
            "rk_ota --misc=update --tar_path=${REMOTE_UPDATE_PATH} --save_dir=${REMOTE_SAVE_DIR} --partition=all"; then
            print_status "OTA update command executed successfully!"
        else
            print_error "OTA update command failed!"
            exit 1
        fi
    fi
    
    print_warning "The device will reboot to complete the update."
    print_status "Update process initiated. Please wait for the device to reboot."
}

# Function to wait for device to come back online
wait_for_device() {
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would wait for device to come back online after reboot"
        print_status "Device is back online! (dry run)"
        return 0
    fi
    
    print_status "Waiting for device to come back online..."
    
    local max_attempts=60  # 5 minutes (60 * 5 seconds)
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p "$SSH_PORT" \
            "${DEVICE_USER}@${DEVICE_IP}" "echo 'Device is online'" &> /dev/null; then
            print_status "Device is back online!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -ne "\rWaiting... ($attempt/$max_attempts)"
        sleep 5
    done
    
    echo
    print_error "Device did not come back online within expected time."
    return 1
}

# Function to verify update
verify_update() {
    print_status "Verifying update..."
    
    # You can add version checking or other verification here
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would verify device responsiveness with: uname -a"
        print_status "Device is responsive after update. (dry run)"
    else
        if ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" \
            "${DEVICE_USER}@${DEVICE_IP}" "uname -a"; then
            print_status "Device is responsive after update."
        else
            print_error "Failed to connect to device after update."
            exit 1
        fi
    fi
}

# Main execution
main() {
    print_status "JetKVM Firmware Build and Update Script"
    print_status "======================================="
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ip)
                DEVICE_IP="$2"
                shift 2
                ;;
            --user)
                DEVICE_USER="$2"
                shift 2
                ;;
            --port)
                SSH_PORT="$2"
                shift 2
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --ip <IP>           Device IP address (default: 192.168.1.100)"
                echo "  --user <USER>       SSH username (default: root)"
                echo "  --port <PORT>       SSH port (default: 22)"
                echo "  --skip-build        Skip building firmware, use existing file"
                echo "  --dry-run           Run in dry run mode (show what would be done without executing)"
                echo "  --help              Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "Running in DRY RUN mode - no actual changes will be made"
    fi
    
    print_status "Target device: ${DEVICE_USER}@${DEVICE_IP}:${SSH_PORT}"
    print_status "Using SSH key authentication"
    
    # Test SSH connection
    print_status "Testing SSH connection..."
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would test SSH connection to ${DEVICE_USER}@${DEVICE_IP}:${SSH_PORT}"
        print_status "SSH connection successful! (dry run)"
    else
        if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p "$SSH_PORT" \
            "${DEVICE_USER}@${DEVICE_IP}" "echo 'SSH connection successful'" &> /dev/null; then
            print_error "Failed to connect to device. Please check:"
            print_error "  - SSH key is properly configured"
            print_error "  - Device IP address is correct"
            print_error "  - Device is powered on and accessible"
            exit 1
        fi
    fi
    
    # Check dependencies
    check_dependencies
    
    # Build firmware unless skipped
    if [ "$SKIP_BUILD" != "true" ]; then
        build_firmware
    else
        print_warning "Skipping firmware build, using existing file..."
    fi
    
    # Upload firmware
    upload_firmware
    
    # Perform OTA update
    perform_ota_update
    
    # Wait for device to reboot
    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would wait 10 seconds before checking device status"
    else
        sleep 10  # Give device time to start rebooting
    fi
    wait_for_device
    
    # Verify update
    verify_update
    
    if [ "$DRY_RUN" = true ]; then
        print_status "Dry run completed successfully! No actual changes were made."
    else
        print_status "Firmware update completed successfully!"
    fi
}

# Run main function
main "$@" 
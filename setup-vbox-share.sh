#!/bin/bash

################################################################################
# VirtualBox Shared Folder Setup Script
# Purpose: Automate sharing of SharePoint-PowerAutomate-Tools with Windows VM
# Usage: ./setup-vbox-share.sh [VM_NAME]
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SHARE_NAME="SharePoint-Tools"
HOST_PATH="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_MOUNT_POINT="Z:"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_vboxmanage() {
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VBoxManage not found. Please install VirtualBox."
        exit 1
    fi
    print_success "VBoxManage found"
}

list_vms() {
    print_header "Available VirtualBox VMs"
    VBoxManage list vms | nl -w2 -s'. '
    echo ""
}

select_vm() {
    if [ -n "$1" ]; then
        VM_NAME="$1"
        print_info "Using VM: $VM_NAME"
        return
    fi

    list_vms

    echo -n "Enter VM name (or number from list above): "
    read -r input

    # Check if input is a number
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        VM_NAME=$(VBoxManage list vms | sed -n "${input}p" | cut -d'"' -f2)
    else
        VM_NAME="$input"
    fi

    if [ -z "$VM_NAME" ]; then
        print_error "Invalid VM selection"
        exit 1
    fi

    print_success "Selected VM: $VM_NAME"
}

check_vm_exists() {
    if ! VBoxManage showvminfo "$VM_NAME" &> /dev/null; then
        print_error "VM '$VM_NAME' not found"
        exit 1
    fi
    print_success "VM '$VM_NAME' verified"
}

check_vm_state() {
    VM_STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d'"' -f2)

    if [ "$VM_STATE" = "running" ]; then
        print_warning "VM is currently running"
        echo -n "Do you want to continue anyway? (y/n): "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "Please shut down the VM and run this script again"
            exit 0
        fi
    else
        print_success "VM is not running (state: $VM_STATE)"
    fi
}

remove_existing_share() {
    if VBoxManage showvminfo "$VM_NAME" | grep -q "Name: '$SHARE_NAME'"; then
        print_warning "Shared folder '$SHARE_NAME' already exists"
        echo -n "Remove and recreate? (y/n): "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            VBoxManage sharedfolder remove "$VM_NAME" --name "$SHARE_NAME"
            print_success "Removed existing shared folder"
        else
            print_info "Keeping existing shared folder"
            exit 0
        fi
    fi
}

add_shared_folder() {
    print_header "Adding Shared Folder"

    echo -n "Mount as read-only? (y/n, default: n): "
    read -r readonly

    READONLY_FLAG=""
    if [[ "$readonly" =~ ^[Yy]$ ]]; then
        READONLY_FLAG="--readonly"
        print_info "Configuring as read-only"
    else
        print_info "Configuring with read-write access"
    fi

    VBoxManage sharedfolder add "$VM_NAME" \
        --name "$SHARE_NAME" \
        --hostpath "$HOST_PATH" \
        --automount \
        --auto-mount-point "$DEFAULT_MOUNT_POINT" \
        $READONLY_FLAG

    print_success "Shared folder added successfully"
}

show_summary() {
    print_header "Setup Complete!"

    cat << EOF

${GREEN}Configuration Summary:${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VM Name:          ${YELLOW}$VM_NAME${NC}
Share Name:       ${YELLOW}$SHARE_NAME${NC}
Host Path:        ${YELLOW}$HOST_PATH${NC}
Windows Path:     ${YELLOW}\\\\VBOXSVR\\$SHARE_NAME${NC}
Drive Letter:     ${YELLOW}$DEFAULT_MOUNT_POINT${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${BLUE}Next Steps:${NC}

1. ${YELLOW}Start your Windows VM${NC}

2. ${YELLOW}Install Guest Additions${NC} (if not already installed):
   - In VirtualBox menu: Devices → Insert Guest Additions CD
   - In Windows: Run D:\\VBoxWindowsAdditions.exe
   - Restart the VM

3. ${YELLOW}Access the shared folder${NC} in Windows:
   - Open File Explorer
   - Navigate to: ${GREEN}$DEFAULT_MOUNT_POINT${NC}
   - Or use: ${GREEN}\\\\VBOXSVR\\$SHARE_NAME${NC}

4. ${YELLOW}Map to drive letter${NC} (optional):
   ${GREEN}net use $DEFAULT_MOUNT_POINT \\\\VBOXSVR\\$SHARE_NAME /persistent:yes${NC}

${BLUE}Verify Installation:${NC}
   VBoxManage showvminfo "$VM_NAME" | grep "Shared folders"

${BLUE}Documentation:${NC}
   See VIRTUALBOX_SHARING_GUIDE.md for detailed instructions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

create_windows_helper_script() {
    print_header "Creating Windows Helper Script"

    HELPER_SCRIPT="$HOST_PATH/mount-share.bat"

    cat > "$HELPER_SCRIPT" << 'EOF'
@echo off
REM ============================================================
REM VirtualBox Shared Folder Mount Helper
REM Purpose: Map SharePoint-PowerAutomate-Tools to Z: drive
REM ============================================================

echo Mounting SharePoint-PowerAutomate-Tools...

REM Map the shared folder to Z: drive
net use Z: \\VBOXSVR\SharePoint-Tools /persistent:yes

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Shared folder mounted to Z:
    echo.
    echo Opening File Explorer...
    explorer Z:\
) else (
    echo.
    echo [ERROR] Failed to mount shared folder
    echo.
    echo Troubleshooting:
    echo 1. Ensure VirtualBox Guest Additions are installed
    echo 2. Check that the VM has "SharePoint-Tools" shared folder configured
    echo 3. Restart the VM and try again
    echo.
    pause
)
EOF

    print_success "Created helper script: $HELPER_SCRIPT"
    print_info "Copy this file to your Windows VM to easily mount the shared folder"
}

################################################################################
# Main
################################################################################

main() {
    print_header "VirtualBox Shared Folder Setup"
    echo ""

    # Step 1: Check prerequisites
    check_vboxmanage

    # Step 2: Select VM
    select_vm "$1"

    # Step 3: Verify VM exists
    check_vm_exists

    # Step 4: Check VM state
    check_vm_state

    # Step 5: Remove existing share if present
    remove_existing_share

    # Step 6: Add shared folder
    add_shared_folder

    # Step 7: Create Windows helper script
    create_windows_helper_script

    # Step 8: Show summary
    show_summary
}

# Run main function with command line argument
main "$@"

# VirtualBox Shared Folder Setup Guide

## Sharing SharePoint-PowerAutomate-Tools from Linux Host to Windows Guest

### Prerequisites
- VirtualBox installed on Linux host
- Windows VM configured and running
- VirtualBox Guest Additions installed in Windows VM (required for shared folders)

---

## Method 1: VirtualBox GUI Setup (Recommended)

### Step 1: Configure Shared Folder in VirtualBox

1. **Shut down your Windows VM** (shared folders work best when configured while VM is off)

2. **Open VirtualBox Manager** on your Linux host

3. **Select your Windows VM** → Click **Settings** → Go to **Shared Folders**

4. **Add a new shared folder**:
   - Click the folder icon with a "+" sign
   - **Folder Path**: `/home/dev/Development/SharePoint-PowerAutomate-Tools`
   - **Folder Name**: `SharePoint-Tools` (this will be the share name in Windows)
   - **Mount Point**: Leave empty (Windows will auto-assign a drive letter)
   - **Options**:
     - ✅ **Auto-mount** (mount automatically on boot)
     - ✅ **Make Permanent** (persist after reboot)
     - ⬜ **Read-only** (leave unchecked if you want to edit files from Windows)

5. **Click OK** to save

### Step 2: Start Windows VM and Access Shared Folder

1. **Start your Windows VM**

2. **Open File Explorer** (Win + E)

3. **Access the shared folder**:
   - Option A: Navigate to **Network** → **VBOXSVR** → **SharePoint-Tools**
   - Option B: Use the UNC path: `\\VBOXSVR\SharePoint-Tools`
   - Option C: Map to a drive letter (see below)

### Step 3: Map Shared Folder to Drive Letter (Optional but Recommended)

In Windows VM:

```batch
REM Map to Z: drive
net use Z: \\VBOXSVR\SharePoint-Tools /persistent:yes
```

Or use GUI:
1. Open **File Explorer**
2. Right-click **This PC** → **Map network drive**
3. Drive: **Z:**
4. Folder: `\\VBOXSVR\SharePoint-Tools`
5. ✅ **Reconnect at sign-in**
6. Click **Finish**

---

## Method 2: VBoxManage Command Line (Advanced)

### Configure from Linux Host Terminal

```bash
# Replace "Windows10" with your actual VM name
VM_NAME="Windows10"
SHARE_NAME="SharePoint-Tools"
HOST_PATH="/home/dev/Development/SharePoint-PowerAutomate-Tools"

# Add shared folder to VM
VBoxManage sharedfolder add "$VM_NAME" \
  --name "$SHARE_NAME" \
  --hostpath "$HOST_PATH" \
  --automount \
  --auto-mount-point "Z:"
```

### Verify Shared Folder Configuration

```bash
# List all shared folders for the VM
VBoxManage showvminfo "$VM_NAME" | grep "Shared folders"
```

### Remove Shared Folder (if needed)

```bash
VBoxManage sharedfolder remove "$VM_NAME" --name "$SHARE_NAME"
```

---

## Troubleshooting

### Issue 1: "Network path not found" or Shared folder not visible

**Solution**: Install VirtualBox Guest Additions

1. **In VirtualBox menu**: Devices → Insert Guest Additions CD image
2. **In Windows VM**: Open File Explorer → CD Drive → Run `VBoxWindowsAdditions.exe`
3. **Restart the VM** after installation
4. **Verify installation**: Check if `VBoxService.exe` is running in Task Manager

### Issue 2: Permission Denied / Access Issues

**Solution A** - Add user to vboxsf group (in Windows VM):
```batch
REM Run as Administrator
net localgroup "Administrators" %USERNAME% /add
```

**Solution B** - Mount with specific permissions from Linux host:
```bash
VBoxManage sharedfolder add "$VM_NAME" \
  --name "$SHARE_NAME" \
  --hostpath "$HOST_PATH" \
  --automount \
  --readonly  # Add this if you only need read access
```

### Issue 3: Shared Folder Disconnects After Reboot

**Solution**: Ensure "Make Permanent" is checked in VirtualBox settings

Or use command line:
```bash
# Remove transient flag to make it permanent
VBoxManage sharedfolder add "$VM_NAME" \
  --name "$SHARE_NAME" \
  --hostpath "$HOST_PATH" \
  --automount \
  --transient=no
```

### Issue 4: Performance Issues with Large Files

**Solution**: Configure VirtualBox for better I/O performance
```bash
# Enable host I/O cache
VBoxManage storagectl "$VM_NAME" --name "SATA" --hostiocache on

# Increase video memory (helps with large file previews)
VBoxManage modifyvm "$VM_NAME" --vram 128
```

---

## Quick Access Script for Windows VM

Create a batch file on your Windows VM desktop for quick access:

**`Open-SharePoint-Tools.bat`**:
```batch
@echo off
REM Map drive if not already mapped
net use Z: \\VBOXSVR\SharePoint-Tools /persistent:yes 2>nul

REM Open in File Explorer
explorer Z:\

REM Optional: Open specific documentation
REM start Z:\README.md
```

---

## Alternative: Bidirectional Sync (Optional)

If you want changes in Windows to automatically sync back to Linux host (and vice versa), the shared folder already supports this by default (as long as "Read-only" is unchecked).

**Real-time sync is automatic** - files edited in Windows will immediately reflect on Linux host.

---

## Security Considerations

1. **Shared folders bypass some Windows permissions** - files are accessible based on Linux host permissions
2. **Sensitive files**: If your tools contain credentials or secrets, consider using a read-only share
3. **Malware risk**: Ensure Windows VM has antivirus, as malware could access host files through shared folders

---

## Testing the Setup

After configuration, test the shared folder:

### In Windows VM:
```batch
REM Navigate to shared folder
cd \\VBOXSVR\SharePoint-Tools

REM List contents
dir

REM View README
type README.md
```

### In Linux Host:
```bash
# Create a test file
echo "Test from Linux" > /home/dev/Development/SharePoint-PowerAutomate-Tools/TEST_SYNC.txt

# Check if visible in Windows (from Windows VM):
# type \\VBOXSVR\SharePoint-Tools\TEST_SYNC.txt
```

---

## Summary

**Recommended Setup**:
1. Use **VirtualBox GUI** to add shared folder with auto-mount
2. In Windows VM, **map to Z: drive** using `net use` or GUI
3. **Test bidirectional sync** by creating/editing files from both sides

**Project Location in Windows**: `Z:\` (or `\\VBOXSVR\SharePoint-Tools`)

**Documentation Access**:
- README: `Z:\README.md`
- Quick Start: `Z:\QUICK_START.md`
- Scripts: `Z:\scripts\`
- Flows: `Z:\deployed-flows\`

---

**Need Help?**
- VirtualBox Docs: https://www.virtualbox.org/manual/ch04.html#sharedfolders
- Guest Additions: https://www.virtualbox.org/manual/ch04.html#additions-windows

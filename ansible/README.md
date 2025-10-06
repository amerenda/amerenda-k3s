# Raspberry Pi 5 k3s + Longhorn Node Preparation

This Ansible playbook automates the preparation of Raspberry Pi 5 nodes for a k3s cluster with Longhorn distributed storage.

## Prerequisites

- Ansible 2.16+ installed on your control machine
- SSH access to Raspberry Pi nodes (default user: `pi`)
- Network connectivity between control machine and Pi nodes

## Quick Start

### 1. Test Connectivity
```bash
ansible -i inventory.ini rpi -m ping
```

### 2. Update Configuration
Edit `group_vars/rpi.yml` and replace the placeholder SSH key:
```yaml
admin_pubkey: "ssh-ed25519 AAAA... alex@amerenda"
```

### 3. Run the Playbook
```bash
ansible-playbook -i inventory.ini setup-rpi.yml
```

### 4. Run with Custom SSH Key
```bash
ansible-playbook -i inventory.ini setup-rpi.yml -e "admin_pubkey='ssh-ed25519 AAAA... alex@amerenda'"
```

## What This Playbook Does

### System Preparation
- Updates apt cache and optionally upgrades packages
- Installs required packages for k3s and Longhorn
- Configures timezone and locale

### Longhorn Prerequisites
- Installs and enables `open-iscsi` package
- Starts and enables `iscsid` service
- Loads required kernel modules (`nfs`, `iscsi_tcp`)
- Adds modules to `/etc/modules` for persistence

### SSH Configuration
- Creates `.ssh` directory for target user
- Adds admin public key to `authorized_keys`
- Sets correct permissions on SSH files

## Files Structure

```
ansible/
├── inventory.ini              # Host inventory
├── group_vars/
│   └── rpi.yml               # Group variables
├── setup-rpi.yml             # Main playbook
└── README.md                 # This file
```

## Customization

### Inventory
Update `inventory.ini` with your actual IP addresses:
```ini
[rpi]
rpi5-0 ansible_host=10.100.20.10
rpi5-1 ansible_host=10.100.20.11
rpi5-2 ansible_host=10.100.20.12
```

### Variables
Modify `group_vars/rpi.yml` to customize:
- `admin_pubkey`: Your SSH public key
- `do_upgrade`: Set to "yes" to run apt upgrade
- `base_packages`: Additional packages to install
- `kernel_modules`: Additional kernel modules

## Tags

Run specific parts of the playbook:
```bash
# Only install packages
ansible-playbook -i inventory.ini setup-rpi.yml --tags packages

# Only configure Longhorn prerequisites
ansible-playbook -i inventory.ini setup-rpi.yml --tags longhorn

# Only configure SSH
ansible-playbook -i inventory.ini setup-rpi.yml --tags ssh
```

## Verification

After running the playbook, verify the setup:
```bash
# Check iscsid service
ansible -i inventory.ini rpi -m shell -a "systemctl status iscsid"

# Check loaded modules
ansible -i inventory.ini rpi -m shell -a "lsmod | grep -E 'nfs|iscsi'"

# Test SSH key access
ansible -i inventory.ini rpi -m ping
```

## Next Steps

After node preparation, you can:
1. Install k3s on the control plane node
2. Join worker nodes to the cluster
3. Install Longhorn for distributed storage
4. Deploy your applications

## Troubleshooting

### SSH Connection Issues
- Ensure SSH key is correctly formatted
- Check network connectivity
- Verify SSH service is running on Pi nodes

### Longhorn Issues
- Verify `iscsid` service is running: `systemctl status iscsid`
- Check kernel modules are loaded: `lsmod | grep iscsi`
- Ensure all required packages are installed

# GitHub Actions Self-Hosted Runner Setup

This repository contains a Bash script to install and configure a GitHub Actions self-hosted runner on an Ubuntu VM.

The setup is intended for a private Azure VM, but the script can also be used on other Ubuntu Linux VMs.

---

## Prerequisites

Before running the setup script, make sure the following requirements are met.

### 1. Ubuntu VM

The VM should have:

- Ubuntu 24.04 LTS
- x86_64 or ARM64 architecture
- At least 2 vCPUs
- At least 4 GB RAM recommended
- Sufficient disk space for GitHub Actions jobs
- `sudo` access

Example Azure VM:

```text
OS       : Ubuntu 24.04 LTS
CPU      : 2 vCPU
Memory   : 4 GB
Disk     : 64 GB
```
---
### 2. VM Network Connectivity

The VM must have outbound Internet connectivity.

The runner needs to communicate with GitHub.

Test connectivity from the VM:

```bash
curl -I https://github.com
```
You should receive an HTTP response from GitHub.

For a private Azure VM, outbound connectivity can be provided using an Azure NAT Gateway.

#### Important

The VM does not require:

* A public IP
* Inbound Internet access
* SSH access from the Internet
* Network connectivity to AKS

The VM only needs outbound connectivity to GitHub.

---

### 3. Access to the VM

You need administrator/sudo access to the VM.

For a private Azure VM, you can access it through Azure Bastion.

Example:
```bash
Your Machine
     |
     v
Azure Bastion
     |
     v
Private VM
```

---

### 4. GitHub Repository

You need access to the GitHub repository where the self-hosted runner will be registered.

You must have permission to add self-hosted runners.

The repository URL will be provided to the setup script.

Example:
```bash
https://github.com/<organization>/<repository>
```

---

### 5. GitHub Runner Registration Token

Before running the script, obtain a temporary GitHub Actions runner registration token.

Navigate to:
```bash
GitHub Repository
    |
    +-- Settings
          |
          +-- Actions
                |
                +-- Runners
                      |
                      +-- New self-hosted runner
```

Select:
```bash
Linux
x64
```
GitHub will display the runner setup instructions and a temporary registration token.

Keep the token available because the setup script will ask for it.

#### Security

Do not:

* Commit the token to Git
* Put the token in setup-runner.sh
* Put the token in Terraform
* Store the token in a configuration file

The token should only be entered when the script requests it.

## Steps to Perform on the VM

### Step 1: Connect to the VM

Connect to the private VM using Azure Bastion.

Example VM:
```bash
dev-vm-runner-poc
```
After connecting, verify the VM:
```bash
hostname
```
Check the operating system:
```bash
cat /etc/os-release
```
Check the architecture:
```bash
uname -m
```
Expected architecture:
```bash
x86_64
```
----
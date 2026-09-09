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
---
### Step 2: Verify Internet Connectivity

Run:
```bash
curl -I https://github.com
```
Also test GitHub's API:
```bash
curl -I https://api.github.com
```
Both commands should return an HTTP response.

If these fail, verify the VM's outbound network connectivity before continuing.

---
### Step 3: Clone This Repository

Clone this repository on the VM:
```bash
git clone <RUNNER-SETUP-REPOSITORY-URL>
```
Example:
```bash
git clone https://github.com/<organization>/github-runner-setup.git
```
Move into the repository:
```bash
cd github-runner-setup
```
Verify the files:
```bash
ls -la
```
You should see:
```bash
setup-runner.sh
README.md
```

---
### Step 4: Make the Script Executable

Run:
```bash
chmod +x setup-runner.sh
```
Verify:
```bash
ls -l setup-runner.sh
```
The script should have executable permissions.

---
### Step 5: Run the Setup Script

Run:
```bash
sudo ./setup-runner.sh
```
The script will ask for the following information.

GitHub Repository URL

Example:

GitHub repository URL:
```bash
https://github.com/my-org/my-repository
```
Enter the repository where the runner should be registered.

Runner Name

Example:
```bash
Runner name [dev-vm-runner-poc]:
```
You can use:
```bash
dev-vm-runner-poc
```
or provide another unique name.

Runner Labels

Example:
```bash
Runner labels [azure-runner,dev]:
```
You can use:
```bash
azure-runner,dev
```
These labels can later be used in GitHub Actions workflows.

Example:
```bash
runs-on: [self-hosted, azure-runner]
Runner Registration Token
```
When prompted:
```bash
Registration token:
```
Paste the temporary registration token obtained from GitHub.

The token should not be committed or stored in the repository.

---
### Step 6: Wait for Installation

The script will automatically:

Install required packages.
Create the github-runner user.
Detect the VM architecture.
Download the GitHub Actions Runner.
Extract the runner.
Register the runner with GitHub.
Configure the runner as a service.
Enable the service at boot.
Start the runner.
Verify the runner service.

No additional manual installation should be required.

---
### Step 7: Verify the Runner Service

After the script completes, check the runner service.

The script will display the service status.

You can also verify the runner process:
```bash
ps aux | grep Runner.Listener
```
Check the runner directory:
```bash
ls -la /home/github-runner/actions-runner
```

---
### Step 8: Verify the Runner in GitHub

Go to:
```bash
GitHub Repository
    |
    +-- Settings
          |
          +-- Actions
                |
                +-- Runners
```
The VM should appear as an available self-hosted runner.

Example:
```bash
dev-vm-runner-poc
```
The runner should show as:
```bash
Idle
```
or:
```bash
Online
```

---
#### Test the Runner

Create a temporary GitHub Actions workflow:
```bash
name: Test Self-Hosted Runner

on:
  workflow_dispatch:

jobs:
  test-runner:
    runs-on: [self-hosted, azure-runner]

    steps:
      - name: Runner Information
        run: |
          echo "Hostname:"
          hostname

          echo "Current User:"
          whoami

          echo "Operating System:"
          uname -a

          echo "Working Directory:"
          pwd
```

Run the workflow manually from:
```bash
GitHub
  → Actions
  → Test Self-Hosted Runner
  → Run workflow
```
The workflow should execute on the private VM.

Runner User

The runner is configured using a dedicated Linux user:

github-runner

The runner should not run as root.

Runner files are located at:
```bash
/home/github-runner/actions-runner
Network Architecture
```
The self-hosted runner only requires outbound connectivity to GitHub.
```bash
                    GitHub
                       ^
                       |
                 HTTPS / Outbound
                       |
                       |
              +-------------------+
              | Private VM        |
              |                   |
              | GitHub Actions    |
              | Self-Hosted Runner|
              +-------------------+
                       |
                       X
                       |
                       X
                       |
                      AKS
```

#### Service Management
Check Service
```bash
sudo systemctl status actions.runner.service
```
Restart Service
```bash
sudo systemctl restart actions.runner.service
```
Stop Service
```bash
sudo systemctl stop actions.runner.service
```
Start Service
```bash
sudo systemctl start actions.runner.service
```
View Logs
```bash
sudo journalctl -u actions.runner.service -f
```
#### Troubleshooting
```bash
GitHub Runner is Offline
```

Check the VM's Internet connectivity:
```bash
curl -I https://github.com
```
Check the runner service:
```bash
sudo systemctl status actions.runner.service
```
Check service logs:

sudo journalctl -u actions.runner.service -n 100
Runner Registration Failed

Verify:

The GitHub repository URL is correct.
You have permission to add self-hosted runners.
The registration token is from the correct repository.
The registration token has not expired.
The VM can reach GitHub.
Runner Cannot Connect to GitHub

Test:
```bash
curl -I https://github.com
```
and:
```bash
curl -I https://api.github.com
```
If the VM is in a private Azure subnet, verify that outbound Internet connectivity is configured.

#### Security Considerations

The runner registration token is temporary and must be treated as a secret.

Never commit:

GitHub PAT
Runner registration token
GitHub credentials
Private SSH keys
Azure credentials

The runner should run under the dedicated:

github-runner

Linux user.

The VM does not require a public IP or inbound Internet access.

#### Cleanup

When the VM or runner is no longer required, remove the runner from GitHub before permanently deleting the VM.

Go to:
```bash
GitHub Repository
    |
    +-- Settings
          |
          +-- Actions
                |
                +-- Runners
```
Select the runner and remove it.

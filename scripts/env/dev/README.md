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
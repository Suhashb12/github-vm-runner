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
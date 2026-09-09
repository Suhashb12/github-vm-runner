#!/usr/bin/env bash
set -euo pipefail

RUNNER_USER="github-runner"
RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"

echo "=========================================="
echo " GitHub Actions Self-Hosted Runner Setup"
echo "=========================================="

# --------------------------------------------------
# 1. Basic checks
# --------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: Run this script with sudo/root."
  echo "Example: sudo ./setup-runner.sh"
  exit 1
fi

if ! grep -qi "ubuntu" /etc/os-release; then
  echo "WARNING: This script was designed for Ubuntu."
fi

# --------------------------------------------------
# 2. Collect GitHub configuration
# --------------------------------------------------

read -rp "GitHub repository URL: " GITHUB_REPO
read -rp "Runner name [dev-vm-runner-poc]: " RUNNER_NAME
RUNNER_NAME="${RUNNER_NAME:-dev-vm-runner-poc}"

read -rp "Runner labels [azure-runner,dev]: " RUNNER_LABELS
RUNNER_LABELS="${RUNNER_LABELS:-azure-runner,dev}"

echo
echo "Enter the temporary GitHub Actions runner registration token."
echo "You can obtain it from:"
echo "GitHub -> Repository -> Settings -> Actions -> Runners -> New self-hosted runner"
echo

read -rsp "Registration token: " RUNNER_TOKEN
echo
echo

if [[ -z "${GITHUB_REPO}" || -z "${RUNNER_TOKEN}" ]]; then
  echo "ERROR: Repository URL and registration token are required."
  exit 1
fi

# --------------------------------------------------
# 3. Install prerequisites
# --------------------------------------------------

echo "[1/7] Installing prerequisites..."

apt-get update

apt-get install -y \
  curl \
  git \
  jq \
  unzip \
  ca-certificates \
  libicu-dev \
  libkrb5-3 \
  zlib1g \
  libssl3 \
  libstdc++6

# --------------------------------------------------
# 4. Create dedicated runner user
# --------------------------------------------------

echo "[2/7] Creating runner user..."

if ! id "${RUNNER_USER}" >/dev/null 2>&1; then
  useradd \
    --create-home \
    --shell /bin/bash \
    "${RUNNER_USER}"
fi

mkdir -p "${RUNNER_DIR}"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "/home/${RUNNER_USER}"

# --------------------------------------------------
# 5. Determine latest runner version
# --------------------------------------------------

echo "[3/7] Detecting latest runner version..."

RUNNER_VERSION="$(
  curl -fsSL \
    https://api.github.com/repos/actions/runner/releases/latest \
    | jq -r '.tag_name' \
    | sed 's/^v//'
)"

if [[ -z "${RUNNER_VERSION}" || "${RUNNER_VERSION}" == "null" ]]; then
  echo "ERROR: Unable to determine GitHub Actions Runner version."
  exit 1
fi

echo "Runner version: ${RUNNER_VERSION}"

# --------------------------------------------------
# 6. Download and configure runner
# --------------------------------------------------

echo "[4/7] Installing GitHub Actions Runner..."

ARCH="$(uname -m)"

case "${ARCH}" in
  x86_64)
    RUNNER_ARCH="x64"
    ;;
  aarch64|arm64)
    RUNNER_ARCH="arm64"
    ;;
  *)
    echo "ERROR: Unsupported architecture: ${ARCH}"
    exit 1
    ;;
esac

RUNNER_PACKAGE="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PACKAGE}"

if [[ ! -f "${RUNNER_DIR}/run.sh" ]]; then

  sudo -u "${RUNNER_USER}" \
    curl -fL "${RUNNER_URL}" \
    -o "${RUNNER_DIR}/${RUNNER_PACKAGE}"

  sudo -u "${RUNNER_USER}" \
    tar -xzf "${RUNNER_DIR}/${RUNNER_PACKAGE}" \
    -C "${RUNNER_DIR}"

  rm -f "${RUNNER_DIR}/${RUNNER_PACKAGE}"

else
  echo "GitHub Actions Runner is already downloaded."
fi

chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"

# --------------------------------------------------
# 7. Register runner
# --------------------------------------------------

echo "[5/7] Registering runner with GitHub..."

if [[ ! -f "${RUNNER_DIR}/.runner" ]]; then

  sudo -u "${RUNNER_USER}" \
    "${RUNNER_DIR}/config.sh" \
      --url "${GITHUB_REPO}" \
      --token "${RUNNER_TOKEN}" \
      --name "${RUNNER_NAME}" \
      --labels "${RUNNER_LABELS}" \
      --unattended \
      --replace

else

  echo "Runner is already configured."

fi

# Remove token from shell environment
unset RUNNER_TOKEN

# --------------------------------------------------
# 8. Install systemd service
# --------------------------------------------------

echo "[6/7] Installing runner service..."

cd "${RUNNER_DIR}"

# Install service only if it does not already exist
if ! ls /etc/systemd/system/actions.runner.*.service >/dev/null 2>&1; then

  ./svc.sh install "${RUNNER_USER}"

else

  echo "Runner service already exists."

fi

systemctl daemon-reload

# --------------------------------------------------
# Find actual GitHub Actions runner service
# --------------------------------------------------

RUNNER_SERVICE="$(
  systemctl list-unit-files \
    'actions.runner.*.service' \
    --no-legend \
    | awk '{print $1}' \
    | head -n 1
)"

if [[ -z "${RUNNER_SERVICE}" ]]; then
  echo "ERROR: Could not find GitHub Actions runner systemd service."
  echo
  echo "Available runner services:"
  systemctl list-unit-files | grep 'actions.runner' || true
  exit 1
fi

echo "Runner service detected:"
echo "${RUNNER_SERVICE}"

# --------------------------------------------------
# Enable and start service
# --------------------------------------------------

systemctl enable "${RUNNER_SERVICE}"
systemctl restart "${RUNNER_SERVICE}"

# --------------------------------------------------
# 9. Verify
# --------------------------------------------------

echo "[7/7] Verifying runner..."

sleep 5

if systemctl is-active --quiet "${RUNNER_SERVICE}"; then

  echo
  echo "=========================================="
  echo " Runner setup completed successfully"
  echo "=========================================="
  echo
  echo "Runner name : ${RUNNER_NAME}"
  echo "Repository  : ${GITHUB_REPO}"
  echo "Labels      : ${RUNNER_LABELS}"
  echo "Service     : ${RUNNER_SERVICE}"
  echo
  echo "Service status:"
  systemctl --no-pager --full status "${RUNNER_SERVICE}"

else

  echo
  echo "ERROR: Runner service is not running."
  echo
  systemctl --no-pager --full status "${RUNNER_SERVICE}" || true
  exit 1

fi
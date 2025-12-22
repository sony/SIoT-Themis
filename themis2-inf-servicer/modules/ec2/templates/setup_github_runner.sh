#!/bin/bash
set -e

# Create runner user if not exists
id -u runner &>/dev/null || useradd -m -s /bin/bash runner
echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner
chmod 440 /etc/sudoers.d/runner

# Add runner user to docker group
usermod -aG docker runner

# Variables from environment
# OWNER, GH_REPOS, GH_PAT, ENV, RUNNER_TAG_NAME, RUNNER_VERSION are set as environment variables
RUNNER_VERSION="2.327.1"

# Download and extract the runner software once
RUNNER_TGZ="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TGZ}"
RUNNER_DIST_DIR="/opt/actions-runner-dist"
RUNNER_BASE_DIR="${RUNNER_DIST_DIR}/actions-runner"

mkdir -p "$RUNNER_DIST_DIR"
cd "$RUNNER_DIST_DIR"

if [ ! -f "$RUNNER_TGZ" ]; then
  curl -o "$RUNNER_TGZ" -L "$RUNNER_URL"
fi

if [ ! -d "$RUNNER_BASE_DIR" ]; then
  mkdir "$RUNNER_BASE_DIR"
  tar xzf "$RUNNER_TGZ" -C "$RUNNER_BASE_DIR"
  chown -R runner:runner "$RUNNER_BASE_DIR"
fi

# Convert GH_REPOS to array
read -ra REPO_ARRAY <<< "$GH_REPOS"

# Register and start runners
for idx in "${!REPO_ARRAY[@]}"; do
  REPO_NAME="${REPO_ARRAY[$idx]}"

  # Generate registration token for this repo on-the-fly
  TOKEN=$(curl -s -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_PAT}" \
    "https://api.github.com/repos/${OWNER}/${REPO_NAME}/actions/runners/registration-token" | jq -r .token)
  if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "Failed to get registration token for ${OWNER}/${REPO_NAME}"
    exit 1
  fi

  RUNNER_DIR="/home/runner/actions-runner-${OWNER}-${REPO_NAME}"
  sudo -u runner mkdir -p "$RUNNER_DIR"
  sudo rsync -a "$RUNNER_BASE_DIR/" "$RUNNER_DIR/"
  chown -R runner:runner "$RUNNER_DIR"
  cd "$RUNNER_DIR"
  RUNNER_NAME="runner-${ENV}-$(hostname)-$(date +%Y%m%d-%H%M%S)"
  sudo -u runner ./config.sh --unattended --url "https://github.com/$OWNER/$REPO_NAME" --token "$TOKEN" --name "$RUNNER_NAME" --labels "$RUNNER_TAG_NAME" --work "_work"
  sudo -u runner sudo ./svc.sh install runner
  sudo -u runner sudo ./svc.sh start
done

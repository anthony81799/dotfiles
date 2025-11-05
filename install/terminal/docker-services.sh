#!/usr/bin/env bash
# ===============================================
# Docker and Self-Hosted Services Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library functions (spinner, okay_message, etc.)
# NOTE: This assumes 'lib.sh' is in the source path
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/docker-services-install.log"
# Initialize logging to file
init_log "$LOG_FILE"

ensure_gum

banner "Docker and Self-Hosted Services Setup"

# Define base directory for persistent container data
DOCKER_VOLUME_BASE="${XDG_DATA_HOME}/docker/volumes"
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"

# --- 1. Install Docker and Setup User Permissions ---
if ! has_cmd docker; then
    if gum confirm "Docker is not installed. Install now?"; then
        spinner "Installing Docker..."
        sudo dnf install -y dnf-plugins-core
        sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce \
            docker-ce-cli containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin || {
            fail_message "Failed to install Docker dependencies."
            exit 1
        }

        spinner "Enabling and starting Docker service..."
        sudo systemctl enable --now docker.service || {
            warn_message "Failed to enable docker service. You may need to run 'sudo systemctl enable --now docker' manually."
        }

        # Add current user to the docker group for password-less container management
        if ! id -nG "$USER" | grep -qw "docker"; then
            spinner "Adding user '$USER' to the 'docker' group..."
            sudo usermod -aG docker "$USER" || {
                warn_message "Failed to add user to docker group. You will need to log out and back in for changes to take effect."
            }
        fi

        okay_message "Docker installed and service started. (A re-login is required to use 'docker' without 'sudo')."
    else
        info_message "Docker installation skipped. Cannot proceed with services setup."
        exit 0
    fi
else
    info_message "Docker is already installed. Proceeding to services setup."
fi

# Ensure base volume directory exists and is owned by the current user
spinner "Creating base directory for container volumes: $DOCKER_VOLUME_BASE..."
mkdir -p "$DOCKER_VOLUME_BASE"
sudo chown -R "$USER_ID":"$GROUP_ID" "$DOCKER_VOLUME_BASE"

# --- 2. Setup Portainer (Container Management Dashboard) ---
spinner "Setting up Portainer (Web UI on port 9000)..."

docker volume create portainer_data &>/dev/null || true # Ensure the named volume exists

sudo docker run -d \
    --name portainer \
    --restart unless-stopped \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest || {
    warn_message "Failed to start Portainer."
}

# --- 3. Setup Self-Hosted Applications ---
info_message "Starting installation of self-hosted applications..."

# --- i. SearxNG (Privacy-Respecting Metasearch Engine) ---
spinner "Starting SearxNG (Web UI on port 8080)..."
sudo docker run -d \
    --name searxng \
    --restart unless-stopped \
    -p 8080:8080 \
    -v "$DOCKER_VOLUME_BASE/searxng:/etc/searxng" \
    searxng/searxng:latest || {
    warn_message "Failed to start SearxNG."
}

# --- ii. Syncthing (File Synchronization) ---
spinner "Starting Syncthing (Web UI on port 8384)..."
sudo docker run -d \
    --name syncthing \
    --restart unless-stopped \
    -p 8384:8384 \
    -p 22000:22000/tcp \
    -p 22000:22000/udp \
    -v "$DOCKER_VOLUME_BASE/syncthing/config:/config" \
    -v "$DOCKER_VOLUME_BASE/syncthing/data:/data" \
    -e PUID="$USER_ID" \
    -e PGID="$GROUP_ID" \
    syncthing/syncthing:latest || {
    warn_message "Failed to start Syncthing."
}

# --- iii. Kopia (Cross-Platform Backup Tool) ---
spinner "Starting Kopia Server (Web UI on port 5151)..."
sudo docker run -d \
    --name kopia-server \
    --restart unless-stopped \
    -p 5151:5151 \
    -v "$DOCKER_VOLUME_BASE/kopia/cache:/cache" \
    -v "$DOCKER_VOLUME_BASE/kopia/config:/config" \
    kopia/server:latest || {
    warn_message "Failed to start Kopia Server."
}

# --- iv. PairDrop (P2P Local File Transfer) ---
spinner "Starting PairDrop (Web UI on port 3000)..."
sudo docker run -d \
    --name pairdrop \
    --restart unless-stopped \
    -p 3000:3000 \
    linusg/pairdrop:latest || {
    warn_message "Failed to start PairDrop."
}

# --- v. Vaultwarden (Lightweight Bitwarden Server) ---
spinner "Starting Vaultwarden (Web UI on port 3001)..."
sudop docker run -d \
    --name vaultwarden \
    --restart unless-stopped \
    -p 3001:80 \
    -v "$DOCKER_VOLUME_BASE/vaultwarden/data:/data" \
    vaultwarden/server:latest || {
    warn_message "Failed to start Vaultwarden."
}

# --- vi. Budget-Board (Using LinuxServer's Budge for single-container simplicity) ---
spinner "Starting Budget-Board (Budge) (Web UI on port 3002)..."
sudo docker run -d \
    --name budge-board \
    --restart unless-stopped \
    -p 3002:3000 \
    -v "$DOCKER_VOLUME_BASE/budge:/config" \
    -e PUID="$USER_ID" \
    -e PGID="$GROUP_ID" \
    -e TZ="America/New_York" \
    lscr.io/linuxserver/budge:latest || {
    warn_message "Failed to start Budget-Board (Budge)."
}

okay_message "All requested containers have been deployed."

echo "=========================================================="
echo "SELF-HOSTED SERVICES ACCESS SUMMARY:"
echo "=========================================================="
echo "Container Dashboard (Portainer): http://localhost:9000"
echo "SearxNG (Metasearch):            http://localhost:8080"
echo "Syncthing (Sync):                http://localhost:8384 (Web UI)"
echo "Kopia (Backup):                  http://localhost:5151 (Web UI)"
echo "PairDrop (File Transfer):        http://localhost:3000"
echo "Vaultwarden (Password Manager):  http://localhost:3001"
echo "Budget-Board (Budge):            http://localhost:3002"
echo "Data Volumes Location:           $DOCKER_VOLUME_BASE"
echo "=========================================================="

finish "Docker services installation complete! Please log out and log back in to use Docker without 'sudo'."

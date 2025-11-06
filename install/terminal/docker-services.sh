#!/usr/bin/env bash
# ===============================================
# Docker and Self-Hosted Services Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library functions
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
DOCKER_SERVICE_STARTED=true
FAILED_SERVICES=()

# --- 1. Install Docker and Setup User Permissions ---
if ! has_cmd docker; then
    if gum confirm "Docker is not installed. Install now?"; then
        spinner "Installing Docker... (This will add the official Fedora Docker repository)"
        sudo dnf install -y dnf-plugins-core
        sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

        INSTALL_SUCCESS=false
        if sudo dnf install -y docker-ce \
            docker-ce-cli containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin; then
            INSTALL_SUCCESS=true
        else
            fail_message "Failed to install Docker dependencies. Skipping Docker setup."
        fi

        if [ "$INSTALL_SUCCESS" = true ]; then
            spinner "Enabling and starting Docker service..."
            sudo systemctl enable --now docker.service || {
                DOCKER_SERVICE_STARTED=false
                warn_message "Failed to enable docker service. You may need to run 'sudo systemctl enable --now docker' manually."
            }

            spinner "Adding current user to the docker group..."
            sudo usermod -aG docker "$USER" || {
                warn_message "Failed to add user to docker group. You will need to run 'sudo usermod -aG docker $USER' and log out/in."
            }
            if [ "$DOCKER_SERVICE_STARTED" = true ]; then
                okay_message "Docker installed and service enabled."
            fi
        fi
    else
        info_message "Docker installation skipped by user."
        finish "Docker setup complete."
    fi
else
    info_message "Docker already installed. Proceeding to container deployment."
fi

# --- 2. Container Deployment Menu ---
if gum confirm "Do you want to deploy self-hosted services now?"; then
    # Ensure Docker is running and user is in the group (or using sudo for testing)
    if ! has_cmd docker; then
        fail_message "Docker is not installed or not in PATH. Skipping container deployment."
        finish "Docker setup complete."
    fi

    # --- i. Portainer (Container Dashboard) ---
    spinner "Starting Portainer (Web UI on port 9000)..."
    sudo docker volume create portainer_data
    sudo docker run -d -p 8000:8000 -p 9000:9000 --name portainer \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest || {
        warn_message "Failed to start Portainer."
        FAILED_SERVICES+=("Portainer")
    }

    # --- ii. SearxNG (Metasearch) ---
    spinner "Starting SearxNG (Web UI on port 8080)..."
    sudo docker run -d \
        --name searxng \
        --restart unless-stopped \
        -p 8080:8080 \
        -v "$DOCKER_VOLUME_BASE/searxng:/etc/searxng:ro" \
        searxng/searxng:latest || {
        warn_message "Failed to start SearxNG."
        FAILED_SERVICES+=("SearxNG")
    }

    # --- iii. Syncthing (Sync) ---
    spinner "Starting Syncthing (Web UI on port 8384)..."
    sudo docker run -d \
        --name syncthing \
        --restart unless-stopped \
        -p 8384:8384 \
        -p 22000:22000/tcp \
        -p 22000:22000/udp \
        -p 21027:21027/udp \
        -v "$DOCKER_VOLUME_BASE/syncthing:/var/syncthing" \
        -e PUID="$USER_ID" \
        -e PGID="$GROUP_ID" \
        lscr.io/linuxserver/syncthing:latest || {
        warn_message "Failed to start Syncthing."
        FAILED_SERVICES+=("Syncthing")
    }

    # --- iv. Kopia (Backup) ---
    spinner "Starting Kopia (Web UI on port 5151)..."
    sudo docker run -d \
        --name kopia-server \
        --restart unless-stopped \
        -p 5151:5151 \
        -v "$DOCKER_VOLUME_BASE/kopia:/cache" \
        -v "$HOME:/mnt/host" \
        -e KOPIA_PASSWORD="your_secure_password" \
        kopia/kopia:latest server start --insecure --upgrader-repository=false || {
        warn_message "Failed to start Kopia."
        FAILED_SERVICES+=("Kopia")
    }
    warn_message "Kopia server started on port 5151. Initial setup password is 'your_secure_password'. PLEASE CHANGE IT IMMEDIATELY."

    # --- v. PairDrop (File Transfer) ---
    spinner "Starting PairDrop (Web UI on port 3000)..."
    sudo docker run -d \
        --name pairdrop \
        --restart unless-stopped \
        -p 3000:3000 \
        ghcr.io/pairdrop/pairdrop:latest || {
        warn_message "Failed to start PairDrop."
        FAILED_SERVICES+=("PairDrop")
    }

    # --- vi. Vaultwarden (Password Manager) ---
    spinner "Starting Vaultwarden (Web UI on port 3001)..."
    sudo docker run -d \
        --name vaultwarden \
        --restart unless-stopped \
        -p 3001:80 \
        -v "$DOCKER_VOLUME_BASE/vaultwarden:/data" \
        vaultwarden/server:latest || {
        warn_message "Failed to start Vaultwarden."
        FAILED_SERVICES+=("Vaultwarden")
    }

    # --- vii. Budget-Board (Budge) ---
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
        warn_message "Failed to start Budget-Board."
        FAILED_SERVICES+=("Budget-Board")
    }

    if [ "${#FAILED_SERVICES[@]}" -eq 0 ]; then
        okay_message "All requested containers have been deployed."
    else
        warn_message "Some containers failed to deploy: ${FAILED_SERVICES[*]}. Check $LOG_FILE for details."
    fi

    # ----------------------------------------------------------
    # --- SERVICES ACCESS SUMMARY (Conditional Display) ---
    # ----------------------------------------------------------

    # Helper function to check if a service failed
    is_failed() {
        local service_name="$1"
        for failed_service in "${FAILED_SERVICES[@]}"; do
            [[ "$failed_service" == "$service_name" ]] && return 0
        done
        return 1
    }

    echo "=========================================================="
    echo "SELF-HOSTED SERVICES ACCESS SUMMARY (Successful Deployments):"
    echo "=========================================================="

    if ! is_failed "Portainer"; then
        echo "Container Dashboard (Portainer): http://localhost:9000"
    fi

    if ! is_failed "SearxNG"; then
        echo "SearxNG (Metasearch):            http://localhost:8080"
    fi

    if ! is_failed "Syncthing"; then
        echo "Syncthing (Sync):                http://localhost:8384 (Web UI)"
    fi

    if ! is_failed "Kopia"; then
        echo "Kopia (Backup):                  http://localhost:5151 (Web UI)"
    fi

    if ! is_failed "PairDrop"; then
        echo "PairDrop (File Transfer):        http://localhost:3000"
    fi

    if ! is_failed "Vaultwarden"; then
        echo "Vaultwarden (Password Manager):  http://localhost:3001"
    fi

    if ! is_failed "Budget-Board"; then
        echo "Budget-Board (Budge):            http://localhost:3002"
    fi

    echo "=========================================================="

else
    info_message "Container deployment skipped."
fi

finish "Docker setup complete."

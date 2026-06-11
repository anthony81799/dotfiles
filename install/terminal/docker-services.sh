#!/usr/bin/env bash
# ===============================================
# Docker and Self-Hosted Services Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library functions
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/docker-services-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Docker and Self-Hosted Services Setup"

# Define base directory for persistent container data
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

export DOCKER_VOLUME_BASE="${XDG_DATA_HOME}/docker/volumes"
export USER_ID="$(id -u)"
export GROUP_ID="$(id -g)"

# --- 1. Install Docker and Setup User Permissions ---
if ! has_cmd docker; then
	if gum confirm "Docker is not installed. Install now?"; then
		log "Installing dnf-plugins-core and adding Docker repository."
		sudo dnf install -y dnf-plugins-core >/dev/null 2>&1

		if has_cmd dnf5; then
			sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo >/dev/null 2>&1
		elif has_cmd dnf-3; then
			sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo >/dev/null 2>&1
		else
			sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo >/dev/null 2>&1
		fi

		info_message "Installing Docker packages (ce, cli, containerd, plugins)..."
		sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
			fail_message "Failed to install Docker packages. Skipping setup."
		}

		info_message "Enabling service and adding user to 'docker' group..."

		sudo systemctl enable --now docker.service || {
			warn_message "Failed to enable docker service. Run 'sudo systemctl enable --now docker.service manually."
		}

		sudo usermod -aG docker "$USER" || {
			warn_message "Failed to add user to docker group. You must log out/in for 'docker' command to work without 'sudo'."
		}

		okay_message "Docker installed."
	else
		info_message "Docker installation skipped by user."
		finish "Docker setup complete."
	fi
else
	info_message "Docker already installed. Proceeding to container deployment."
fi

# --- 2. Container Deployment ---

if gum confirm "Do you want to deploy self-hosted services now?"; then
	if ! has_cmd docker; then
		fail_message "Docker is not installed or not in PATH. Skipping container deployment."
		finish "Docker setup complete."
	fi

	# Generate (or reuse) a random Kopia server password
	KOPIA_PASSWORD_FILE="${XDG_DATA_HOME}/docker/kopia-password"
	mkdir -p "$(dirname "$KOPIA_PASSWORD_FILE")"
	if [ ! -f "$KOPIA_PASSWORD_FILE" ]; then
		head -c 24 /dev/urandom | base64 >"$KOPIA_PASSWORD_FILE"
		chmod 600 "$KOPIA_PASSWORD_FILE"
	fi
	export KOPIA_PASSWORD
	KOPIA_PASSWORD="$(cat "$KOPIA_PASSWORD_FILE")"

	info_message "Starting all services via Docker Compose..."

	if docker compose -f "$COMPOSE_FILE" up -d; then
		warn_message "Kopia server is running on http://localhost:5151. Password saved to $KOPIA_PASSWORD_FILE"
		okay_message "All services deployed."
	else
		warn_message "One or more services failed to start. Check $LOG_FILE for details."
	fi

	# --- SERVICES ACCESS SUMMARY ---

	echo ""
	echo "=========================================================="
	echo "SELF-HOSTED SERVICES ACCESS SUMMARY:"
	echo "=========================================================="
	printf "%-35s %s\n" "Container Dashboard (Portainer):" "http://localhost:9000"
	printf "%-35s %s\n" "SearxNG (Metasearch):"            "http://localhost:8080"
	printf "%-35s %s\n" "Syncthing (Sync):"                "http://localhost:8384"
	printf "%-35s %s\n" "Kopia (Backup):"                  "http://localhost:5151"
	printf "%-35s %s\n" "Vaultwarden (Password Manager):"  "http://localhost:3001"
	printf "%-35s %s\n" "Budget-Board (Budge):"            "http://localhost:3002"
	echo "=========================================================="

else
	info_message "Container deployment skipped."
fi

finish "Docker setup complete."

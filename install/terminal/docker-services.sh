#!/usr/bin/env bash
# ===============================================
# Docker and Self-Hosted Services Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library functions
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/docker-services-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Docker and Self-Hosted Services Setup"

# Define base directory for persistent container data
DOCKER_VOLUME_BASE="${XDG_DATA_HOME}/docker/volumes"
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"
DOCKER_SERVICE_STARTED=true
FAILED_SERVICES=()

# --- HELPER FUNCTIONS ---

deploy_service() {
	local display_name="$1"
	local container_name="$2"
	local web_port="$3"
	local run_args="$4"
	local image_and_cmd="$5"
	local restart_policy="$6"
	local pre_command="$7"

	spinner "Starting $display_name (Web UI on port $web_port)..."

	if [[ -n "$pre_command" ]]; then
		eval "$pre_command" >/dev/null 2>&1 || true
	fi

	# shellcheck disable=SC2086
	if docker run -d --name "$container_name" --restart "$restart_policy" $run_args $image_and_cmd; then
		if [[ "$display_name" == "Kopia" ]]; then
			warn_message "Kopia server started on port 5151. Initial setup password is 'your_secure_password'. PLEASE CHANGE IT IMMEDIATELY."
		fi
		return 0
	else
		warn_message "Failed to start $display_name."
		FAILED_SERVICES+=("$display_name")
		return 1
	fi
}

is_failed() {
	local service_name="$1"
	for failed_service in "${FAILED_SERVICES[@]}"; do
		[[ "$failed_service" == "$service_name" ]] && return 0
	done
	return 1
}

# --- 1. Install Docker and Setup User Permissions ---
if ! has_cmd docker; then
	if gum confirm "Docker is not installed. Install now?"; then
		log "Installing dnf-plugins-core and adding Docker repository."
		sudo dnf install -y dnf-plugins-core >/dev/null 2>&1
		sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo >/dev/null 2>&1

		spinner "Installing Docker packages (ce, cli, containerd, plugins)..."
		sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
			fail_message "Failed to install Docker packages. Skipping setup."
		}

		spinner "Enabling service and adding user to 'docker' group..."

		sudo systemctl enable --now docker.service || {
			DOCKER_SERVICE_STARTED=false
			warn_message "Failed to enable docker service. Run 'sudo systemctl enable --now docker' manually."
		}

		sudo usermod -aG docker "$USER" || {
			warn_message "Failed to add user to docker group. You must log out/in for 'docker' command to work without 'sudo'."
		}

		if [ "$DOCKER_SERVICE_STARTED" = true ]; then
			okay_message "Docker installed and service enabled."
		fi
	else
		info_message "Docker installation skipped by user."
		finish "Docker setup complete."
	fi
else
	info_message "Docker already installed. Proceeding to container deployment."
fi

# --- 2. Container Deployment Menu ---

# Configuration Array:
# Display Name | Container Name | Web UI Port | Docker Run Arguments | Image and Command | Restart Policy | Pre-Command (e.g., volume create)
declare -a SERVICES_CONFIG=(
	"Portainer|portainer|9000|-v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -p 8000:8000 -p 9000:9000|portainer/portainer-ce:latest|always|docker volume create portainer_data"
	"SearxNG|searxng|8080|-p 8080:8080 -v \"$DOCKER_VOLUME_BASE/searxng:/etc/searxng:ro\"|searxng/searxng:latest|unless-stopped|"
	"Syncthing|syncthing|8384|-p 8384:8384 -p 22000:22000/tcp -p 22000:22000/udp -p 21027:21027/udp -v \"$DOCKER_VOLUME_BASE/syncthing:/var/syncthing\" -e PUID=\"$USER_ID\" -e PGID=\"$GROUP_ID\"|lscr.io/linuxserver/syncthing:latest|unless-stopped|"
	"Kopia|kopia-server|5151|-p 5151:5151 -v \"$DOCKER_VOLUME_BASE/kopia:/cache\" -v \"$HOME:/mnt/host\" -e KOPIA_PASSWORD=\"your_secure_password\"|kopia/kopia:latest server start --insecure --upgrader-repository=false|unless-stopped|"
	"Vaultwarden|vaultwarden|3001|-p 3001:80 -v \"$DOCKER_VOLUME_BASE/vaultwarden:/data\"|vaultwarden/server:latest|unless-stopped|"
	"Budget-Board|budge-board|3002|-p 3002:3000 -v \"$DOCKER_VOLUME_BASE/budge:/config\" -e PUID=\"$USER_ID\" -e PGID=\"$GROUP_ID\" -e TZ=\"America/New_York\"|lscr.io/linuxserver/budge:latest|unless-stopped|"
)

# Service Summary for the final print (Display Name | Label | URL)
declare -a SERVICE_SUMMARY_CONFIG=(
	"Portainer|Container Dashboard (Portainer):|http://localhost:9000"
	"SearxNG|SearxNG (Metasearch):|http://localhost:8080"
	"Syncthing|Syncthing (Sync):|http://localhost:8384 (Web UI)"
	"Kopia|Kopia (Backup):|http://localhost:5151 (Web UI)"
	"Vaultwarden|Vaultwarden (Password Manager):|http://localhost:3001"
	"Budget-Board|Budget-Board (Budge):|http://localhost:3002"
)

if gum confirm "Do you want to deploy self-hosted services now?"; then
	if ! has_cmd docker; then
		fail_message "Docker is not installed or not in PATH. Skipping container deployment."
		finish "Docker setup complete."
	fi

	for config in "${SERVICES_CONFIG[@]}"; do
		IFS='|' read -r display_name container_name web_port run_args image_and_cmd restart_policy pre_command <<<"$config"
		deploy_service "$display_name" "$container_name" "$web_port" "$run_args" "$image_and_cmd" "$restart_policy" "$pre_command"
	done

	if [ "${#FAILED_SERVICES[@]}" -eq 0 ]; then
		okay_message "All requested containers have been deployed."
	else
		warn_message "Some containers failed to deploy: ${FAILED_SERVICES[*]}. Check $LOG_FILE for details."
	fi

	# --- SERVICES ACCESS SUMMARY ---

	echo ""
	echo "=========================================================="
	echo "SELF-HOSTED SERVICES ACCESS SUMMARY (Successful Deployments):"
	echo "=========================================================="

	for config in "${SERVICE_SUMMARY_CONFIG[@]}"; do
		IFS='|' read -r display_name label url <<<"$config"
		if ! is_failed "$display_name"; then
			printf "%-35s %s\n" "$label" "$url"
		fi
	done

	echo "=========================================================="

else
	info_message "Container deployment skipped."
fi

finish "Docker setup complete."

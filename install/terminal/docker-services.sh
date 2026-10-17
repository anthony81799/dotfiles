#!/usr/bin/env bash
# ===============================================
# Media Server (homelab-setup) Installer
# ===============================================
# Stands up the full homelab-setup stack (github.com/anthony81799/homelab-setup)
# on a fresh Fedora machine: Docker, host prerequisites, Tailscale, MariaDB,
# TLS cert, crons, and every container — optionally restoring state from a
# migration bundle made on the old server.
#
#   docker-services.sh                 install / restore on this machine
#   docker-services.sh --export DIR    (old server) write a migration bundle to DIR
#
# Bundle contents: .env, per-app settings snapshots, Nextcloud DB dump, raw
# tars of volumes settings-snapshot.py doesn't cover (Duplicati jobs, Caddy's
# local CA, the cloud Funnel node's identity), rclone config, the git-ignored
# gr-token.patch, and scripts' state files. It holds every secret in the stack
# — keep it off the network and delete it after the restore.
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/docker-services-install.log"
init_log "$LOG_FILE"

REPO_URL="https://github.com/anthony81799/homelab-setup.git"
REPO_DIR="$HOME/homelab-setup"
COMPOSE_PROJECT="nextcloud-compose"
TS_HOST="triton"
TS_FQDN="triton.tailb26ea7.ts.net"
TS_IP="100.90.1.57"
STORAGE="/storage"

# Named volumes not covered by settings-snapshot.py whose contents matter:
# Duplicati's job definitions, Caddy's local CA (the root cert devices trust
# for *.home), and the cloud.* Funnel node's Tailscale identity.
EXTRA_VOLUMES=(duplicati_config caddy_data tailscale_nextcloud_state media_validator_data)

STATE_FILES=(
	playlist-state.json genre-cache.json deezer-top-cache.json
	queue-watchdog-state.json season-order-monitor-state.json
	ombi-request-sync-state.json service-watchdog-state.json
	libgen-fallback-state.json fix-bookshelf-language-state.json
)

CRON_LINES=(
	"0 2,4 * * * /usr/bin/python3 $REPO_DIR/scripts/sync-music-playlists.py >> $REPO_DIR/scripts/music-playlists.log 2>&1"
	"0 3 * * 0 /usr/bin/python3 $REPO_DIR/scripts/sync-music-playlists.py --full >> $REPO_DIR/scripts/music-playlists.log 2>&1"
	"0 1 * * * $REPO_DIR/scripts/nextcloud-db-backup.sh >> $REPO_DIR/backups/nextcloud-db/backup.log 2>&1"
	"*/15 * * * * /usr/bin/python3 $REPO_DIR/scripts/queue-watchdog.py >> $REPO_DIR/scripts/queue-watchdog.log 2>&1"
	"5 0 * * * /usr/bin/python3 $REPO_DIR/scripts/pre-backup-library-sync.py >> $REPO_DIR/scripts/pre-backup-library-sync.log 2>&1"
	"*/5 * * * * $REPO_DIR/scripts/nextcloud-cron.sh >> $REPO_DIR/scripts/nextcloud-cron.log 2>&1"
	"0 3 1 * * $REPO_DIR/scripts/topgrade-monthly.sh >> $REPO_DIR/scripts/topgrade-monthly.log 2>&1"
	"30 2 * * * /usr/bin/python3 $REPO_DIR/scripts/pgs-subtitle-ocr.py >> $REPO_DIR/scripts/pgs-subtitle-ocr.log 2>&1"
	"*/15 * * * * /usr/bin/python3 $REPO_DIR/scripts/season-order-monitor.py >> $REPO_DIR/scripts/season-order-monitor.log 2>&1"
	"45 3 * * * $REPO_DIR/scripts/checkpoint-navidrome-wal.sh >> $REPO_DIR/scripts/checkpoint-navidrome-wal.log 2>&1"
	"*/15 * * * * /usr/bin/python3 $REPO_DIR/scripts/ombi-request-sync.py >> $REPO_DIR/scripts/ombi-request-sync.log 2>&1"
	"*/2 * * * * /usr/bin/python3 $REPO_DIR/scripts/service-watchdog.py >> $REPO_DIR/scripts/service-watchdog.log 2>&1"
	"*/15 * * * * /usr/bin/python3 $REPO_DIR/scripts/fix-bookshelf-language.py >> $REPO_DIR/scripts/fix-bookshelf-language.log 2>&1"
	"30 4 * * 0 /usr/bin/python3 $REPO_DIR/scripts/bookshelf-backfill-books.py >> $REPO_DIR/scripts/bookshelf-backfill-books.log 2>&1"
	"30 1 * * * /usr/bin/python3 $REPO_DIR/scripts/prune-noncanonical-tracks.py >> $REPO_DIR/scripts/prune-noncanonical-tracks.log 2>&1"
	"20 * * * * /usr/bin/python3 $REPO_DIR/scripts/libgen-fallback.py >> $REPO_DIR/scripts/libgen-fallback.log 2>&1"
	"15 5 * * * /usr/bin/python3 $REPO_DIR/scripts/sync-book-covers.py >> $REPO_DIR/scripts/sync-book-covers.log 2>&1"
	"*/15 * * * * /usr/bin/python3 $REPO_DIR/scripts/navidrome-remap-upgrades.py >> $REPO_DIR/scripts/navidrome-remap-upgrades.log 2>&1"
)

compose() { docker compose -f "$REPO_DIR/docker-compose.yml" --project-directory "$REPO_DIR" "$@"; }

env_get() { grep -m1 "^$1=" "$REPO_DIR/.env" 2>/dev/null | cut -d= -f2- || true; }

env_set() {
	local key="$1" val="$2"
	if grep -q "^${key}=" "$REPO_DIR/.env"; then
		python3 - "$REPO_DIR/.env" "$key" "$val" <<-'PY'
			import sys, re
			path, key, val = sys.argv[1:]
			text = open(path).read()
			text = re.sub(rf"^{re.escape(key)}=.*$", lambda _: f"{key}={val}", text, count=1, flags=re.M)
			open(path, "w").write(text)
		PY
	else
		echo "${key}=${val}" >>"$REPO_DIR/.env"
	fi
}

rand_secret() { head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c "${1:-32}"; }

volume_tar() { docker run --rm -v "${COMPOSE_PROJECT}_$1:/v:ro" alpine tar czf - -C /v .; }

# ===============================================
# Export mode (run on the OLD server)
# ===============================================
if [ "${1:-}" = "--export" ]; then
	OUT="${2:?usage: docker-services.sh --export DIR}"
	banner "Media Server Migration Export"
	mkdir -p "$OUT"/{settings,volumes,state}
	chmod 700 "$OUT"

	cp "$REPO_DIR/.env" "$OUT/env"
	[ -f "$REPO_DIR/duplicati-rclone/rclone.conf" ] && cp "$REPO_DIR/duplicati-rclone/rclone.conf" "$OUT/"
	[ -f "$REPO_DIR/patches/rreading-glasses/gr-token.patch" ] && cp "$REPO_DIR/patches/rreading-glasses/gr-token.patch" "$OUT/"
	for f in "${STATE_FILES[@]}"; do
		[ -f "$REPO_DIR/scripts/$f" ] && cp "$REPO_DIR/scripts/$f" "$OUT/state/"
	done

	info_message "Capturing per-app settings snapshots..."
	python3 "$REPO_DIR/scripts/settings-snapshot.py" capture
	cp "$REPO_DIR"/settings/*.tar.gz "$OUT/settings/"

	info_message "Dumping Nextcloud database..."
	"$REPO_DIR/scripts/nextcloud-db-backup.sh"
	cp "$(ls -t "$REPO_DIR"/backups/nextcloud-db/*.sql.gz | head -1)" "$OUT/nextcloud-db.sql.gz"

	info_message "Archiving extra volumes..."
	compose stop duplicati
	for v in "${EXTRA_VOLUMES[@]}"; do
		volume_tar "$v" >"$OUT/volumes/$v.tar.gz"
	done
	compose start duplicati

	okay_message "Bundle written to $OUT ($(du -sh "$OUT" | cut -f1)). It contains every secret in the stack."
	finish "Export complete."
	exit 0
fi

ensure_gum
banner "Media Server Setup"

# --- 1. Docker ---
if ! has_cmd docker; then
	info_message "Installing Docker CE..."
	sudo dnf install -y dnf-plugins-core
	if has_cmd dnf5; then
		sudo dnf config-manager addrepo --overwrite --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
	else
		sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
	fi
	sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
sudo systemctl enable --now docker.service
if ! id -nG "$USER" | grep -qw docker; then
	sudo usermod -aG docker "$USER"
	warn_message "Added $USER to the docker group. Log out/in, then re-run this script."
	finish "Re-run after re-login."
	exit 0
fi

# --- 2. Host packages ---
info_message "Installing host packages (Tailscale, MariaDB, cron, Python deps)..."
if ! has_cmd tailscale; then
	if has_cmd dnf5; then
		sudo dnf config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
	else
		sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
	fi
fi
sudo dnf install -y git tailscale mariadb-server cronie python3-requests unzip curl
sudo systemctl enable --now tailscaled mariadb crond
sudo timedatectl set-timezone America/New_York

if lspci | grep -qi nvidia; then
	if ! has_cmd nvidia-smi; then
		fail_message "NVIDIA GPU found but no driver. Run install/desktop/nvidia.sh, reboot, then re-run this script."
		exit 1
	fi
	if ! has_cmd nvidia-ctk; then
		sudo curl -fsSL -o /etc/yum.repos.d/nvidia-container-toolkit.repo \
			https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
		sudo dnf install -y nvidia-container-toolkit
	fi
	sudo nvidia-ctk runtime configure --runtime=docker
	sudo systemctl restart docker
else
	warn_message "No NVIDIA GPU: Jellyfin's 'runtime: nvidia' will fail. Remove it from docker-compose.yml for this host."
fi

# topgrade-monthly.sh runs unattended from cron and shells out to sudo for these.
SUDOERS_TMP="$(mktemp)"
printf '%s ALL=(root) NOPASSWD: /usr/bin/dnf, /usr/bin/flatpak\n' "$USER" >"$SUDOERS_TMP"
sudo visudo -cf "$SUDOERS_TMP" && sudo install -m 440 "$SUDOERS_TMP" /etc/sudoers.d/homelab-topgrade
rm -f "$SUDOERS_TMP"

# --- 3. Storage ---
if ! mountpoint -q "$STORAGE"; then
	fail_message "$STORAGE is not mounted. Add the data drive to /etc/fstab (see partition-schema.md) and re-run."
	exit 1
fi
sudo mkdir -p "$STORAGE"/media/{Movies,Shows,Music,Books,downloads/torrents,downloads/usenet} "$STORAGE/nextcloud_data"
sudo chown "$USER:$USER" "$STORAGE/media" "$STORAGE"/media/*
[ -e "$HOME/media" ] || ln -s "$STORAGE/media" "$HOME/media"

# --- 4. Tailscale ---
if ! tailscale status >/dev/null 2>&1; then
	info_message "Joining the tailnet as '$TS_HOST' (complete the login in your browser)..."
	sudo tailscale up --hostname="$TS_HOST" --operator="$USER"
fi
sudo tailscale set --operator="$USER"

# Every published port in docker-compose.yml is bound to this exact IP.
while [ "$(tailscale ip -4)" != "$TS_IP" ]; do
	warn_message "This node's Tailscale IP is $(tailscale ip -4), but the stack expects $TS_IP."
	info_message "Admin console → Machines: remove the old '$TS_HOST', then on this node: '...' → Edit machine IPv4 → $TS_IP."
	choice="$(gum choose "I changed it, re-check" "Rewrite the repo for the new IP" "Abort")"
	case "$choice" in
	"Rewrite the repo for the new IP") REWRITE_IP="$(tailscale ip -4)"; break ;;
	"Abort") exit 1 ;;
	esac
done
[ "$(tailscale status --self --json | python3 -c 'import json,sys;print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')" = "$TS_FQDN" ] ||
	warn_message "This node isn't $TS_FQDN — Caddyfile/scripts hardcode that name. Rename the node in the admin console."

# --- 5. Repo ---
if [ ! -d "$REPO_DIR/.git" ]; then
	git clone "$REPO_URL" "$REPO_DIR"
fi
mkdir -p "$REPO_DIR"/{backups/nextcloud-db,settings,bin,duplicati-rclone}
if [ -n "${REWRITE_IP:-}" ]; then
	sed -i "s/${TS_IP//./\\.}/$REWRITE_IP/g" "$REPO_DIR/docker-compose.yml" "$REPO_DIR/Caddyfile" "$REPO_DIR/dnsmasq.conf"
	warn_message "Rewrote $TS_IP → $REWRITE_IP in docker-compose.yml/Caddyfile/dnsmasq.conf (uncommitted)."
fi

if [ ! -x "$REPO_DIR/bin/rclone" ]; then
	info_message "Downloading rclone (mounted into Duplicati for Proton Drive)..."
	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/rclone.zip" https://downloads.rclone.org/rclone-current-linux-amd64.zip
	unzip -q -j "$tmp/rclone.zip" '*/rclone' -d "$REPO_DIR/bin"
	chmod +x "$REPO_DIR/bin/rclone"
	rm -rf "$tmp"
fi

# --- 6. Migration bundle / .env ---
BUNDLE=""
if gum confirm "Restore from a migration bundle (made with --export on the old server)?"; then
	BUNDLE="$(gum input --placeholder "/path/to/bundle")"
	[ -f "$BUNDLE/env" ] || { fail_message "$BUNDLE/env not found."; exit 1; }
	install -m 600 "$BUNDLE/env" "$REPO_DIR/.env"
	[ -f "$BUNDLE/rclone.conf" ] && install -m 600 "$BUNDLE/rclone.conf" "$REPO_DIR/duplicati-rclone/rclone.conf"
	[ -f "$BUNDLE/gr-token.patch" ] && cp "$BUNDLE/gr-token.patch" "$REPO_DIR/patches/rreading-glasses/"
	cp -n "$BUNDLE"/state/* "$REPO_DIR/scripts/" 2>/dev/null || true
	cp "$BUNDLE"/settings/*.tar.gz "$REPO_DIR/settings/" 2>/dev/null || true
elif [ ! -f "$REPO_DIR/.env" ]; then
	info_message "Creating a fresh .env..."
	install -m 600 /dev/null "$REPO_DIR/.env"
	for k in QBT_PASS NEXTCLOUD_DB_PASSWORD DUPLICATI_ENCRYPTION_KEY OMBI_ADMIN_PASS NEXTCLOUD_ADMIN_PASSWORD \
		RREADING_GLASSES_DB_PASSWORD RREADING_GLASSES_GR_DB_PASSWORD SABNZBD_API_KEY; do
		env_set "$k" "$(rand_secret)"
	done
	info_message "Enter account credentials (leave blank to fill in later):"
	for k in PROTONVPN_WG_PRIVATE_KEY PROTONVPN_WG_ADDRESSES FRUGAL_USENET_USER FRUGAL_USENET_PASS \
		HARDCOVER_AUTH TS_AUTHKEY_NEXTCLOUD NTFY_TOPIC_URL WATCHTOWER_NOTIFICATION_URL; do
		env_set "$k" "$(gum input --password --placeholder "$k")"
	done
	env_set PROTONVPN_SERVER_COUNTRY "United States"
	for k in SONARR_API_KEY RADARR_API_KEY LIDARR_API_KEY BOOKSHELF_API_KEY PROWLARR_API_KEY BAZARR_API_KEY \
		JELLYFIN_API_KEY OMBI_API_KEY NEXTCLOUD_SERVERINFO_TOKEN NAVIDROME_SUBSONIC_TOKEN NAVIDROME_SUBSONIC_SALT; do
		env_set "$k" ""
	done
	okay_message ".env created at $REPO_DIR/.env"
fi

# --- 7. MariaDB (Nextcloud's DB lives on the host) ---
DB_PASS="$(env_get NEXTCLOUD_DB_PASSWORD)"
SUBNET="$(grep -A4 '^networks:' "$REPO_DIR/docker-compose.yml" | grep -oP 'subnet: \K[0-9.]+' | cut -d. -f1,2)"
sudo mariadb <<-SQL
	CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
	CREATE USER IF NOT EXISTS 'nextcloud_user'@'localhost' IDENTIFIED BY '${DB_PASS}';
	CREATE USER IF NOT EXISTS 'nextcloud_user'@'${SUBNET}.%' IDENTIFIED BY '${DB_PASS}';
	ALTER USER 'nextcloud_user'@'localhost' IDENTIFIED BY '${DB_PASS}';
	ALTER USER 'nextcloud_user'@'${SUBNET}.%' IDENTIFIED BY '${DB_PASS}';
	GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud_user'@'localhost';
	GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud_user'@'${SUBNET}.%';
	FLUSH PRIVILEGES;
SQL
if [ -n "$BUNDLE" ] && [ -f "$BUNDLE/nextcloud-db.sql.gz" ]; then
	if [ "$(sudo mariadb -N -e 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema="nextcloud"')" = "0" ] ||
		gum confirm "The nextcloud DB already has tables. Overwrite it from the bundle dump?"; then
		info_message "Importing Nextcloud database..."
		gunzip -c "$BUNDLE/nextcloud-db.sql.gz" | sudo mariadb nextcloud
	fi
fi

# --- 8. TLS cert + renewal ---
sudo mkdir -p /etc/ssl/tailscale
sudo tailscale cert --cert-file="/etc/ssl/tailscale/$TS_FQDN.crt" --key-file="/etc/ssl/tailscale/$TS_FQDN.key" "$TS_FQDN"
echo "0 4 * * * root $REPO_DIR/scripts/renew-cert.sh >> /var/log/renew-tailscale-cert.log 2>&1" |
	sudo tee /etc/cron.d/homelab-renew-cert >/dev/null

# --- 9. Containers ---
if [ -n "$BUNDLE" ]; then
	for v in "${EXTRA_VOLUMES[@]}"; do
		tarball="$BUNDLE/volumes/$v.tar.gz"
		[ -f "$tarball" ] || continue
		docker volume inspect "${COMPOSE_PROJECT}_$v" >/dev/null 2>&1 && continue
		info_message "Restoring volume $v..."
		docker volume create --label "com.docker.compose.project=$COMPOSE_PROJECT" \
			--label "com.docker.compose.volume=$v" "${COMPOSE_PROJECT}_$v" >/dev/null
		docker run --rm -i -v "${COMPOSE_PROJECT}_$v:/v" alpine tar xzf - -C /v <"$tarball"
	done
fi

SKIP_SERVICES=()
if [ ! -f "$REPO_DIR/patches/rreading-glasses/gr-token.patch" ]; then
	warn_message "patches/rreading-glasses/gr-token.patch missing (git-ignored) — skipping rreading-glasses-gr + bookshelf."
	SKIP_SERVICES=(rreading-glasses-gr bookshelf)
fi
mapfile -t SERVICES < <(compose config --services | grep -vxF -f <(printf '%s\n' "${SKIP_SERVICES[@]}" ""))

info_message "Pulling and building images..."
compose pull --ignore-buildable "${SERVICES[@]}"
compose build "${SERVICES[@]}"
compose create "${SERVICES[@]}"

if compgen -G "$REPO_DIR/settings/*.tar.gz" >/dev/null; then
	info_message "Restoring per-app settings snapshots..."
	mapfile -t APPS < <(basename -a -s .tar.gz "$REPO_DIR"/settings/*.tar.gz)
	python3 "$REPO_DIR/scripts/settings-snapshot.py" restore "${APPS[@]}"
fi

info_message "Starting the stack..."
compose up -d "${SERVICES[@]}"

# Fresh install: the *arr apps generate their own API keys on first boot.
if [ -z "$BUNDLE" ]; then
	info_message "Collecting generated API keys into .env..."
	for pair in sonarr:SONARR_API_KEY radarr:RADARR_API_KEY lidarr:LIDARR_API_KEY prowlarr:PROWLARR_API_KEY bookshelf:BOOKSHELF_API_KEY; do
		svc="${pair%%:*}" key="${pair#*:}"
		[ -n "$(env_get "$key")" ] && continue
		printf '%s\n' "${SERVICES[@]}" | grep -qxF "$svc" || continue
		val=""
		for _ in $(seq 60); do
			val="$(compose exec -T "$svc" cat /config/config.xml 2>/dev/null | grep -oP '<ApiKey>\K[^<]+' || true)"
			[ -n "$val" ] && break
			sleep 2
		done
		[ -n "$val" ] && env_set "$key" "$val"
	done
	compose up -d "${SERVICES[@]}"

	info_message "Wiring apps together..."
	for s in provision-arr-apps configure-qbittorrent configure-bandwidth-limits configure-media-naming \
		register-media-validator-webhooks add-public-indexers; do
		python3 "$REPO_DIR/scripts/$s.py" || warn_message "$s.py failed — re-run it once the app is fully up."
	done
fi

# --- 10. Funnel (Jellyfin + Ombi public; Nextcloud/Navidrome go via the cloud node container) ---
tailscale funnel --bg --https=8443 "https://$TS_FQDN:8920" || warn_message "Enable Funnel for this node in the admin console, then re-run."
tailscale funnel --bg --https=10000 "https://$TS_FQDN:3579" || true

# --- 11. User crontab ---
current="$(crontab -l 2>/dev/null || true)"
for line in "${CRON_LINES[@]}"; do
	grep -qF "$line" <<<"$current" || current+=$'\n'"$line"
done
sed '/^$/d' <<<"$current" | crontab -
okay_message "Crontab installed (${#CRON_LINES[@]} jobs)."

# --- Summary ---
echo ""
echo "=========================================================="
echo "MEDIA SERVER — REMAINING MANUAL STEPS"
echo "=========================================================="
if [ -n "$BUNDLE" ]; then
	cat <<-EOF
		- Everything was restored from the bundle. Delete it now: rm -rf '$BUNDLE'
		- Media + Nextcloud files come from $STORAGE itself (or a Duplicati restore if it's a new drive).
		- Check https://$TS_FQDN:3000 (dashboard) and Uptime Kuma for anything red.
	EOF
else
	cat <<-EOF
		- Nextcloud: finish the web installer at https://$TS_FQDN (DB host: host-gateway, user nextcloud_user).
		- Jellyfin: run the setup wizard, add libraries (/media/Movies, Shows, Music, Books), create an
		  API key → JELLYFIN_API_KEY in .env, then run configure-jellyfin-default-subtitles.py and
		  configure-jellyfin-trickplay.py.
		- Bazarr, Ombi, Navidrome: copy their API keys/tokens into .env, run provision-ombi.py.
		- Duplicati: 'rclone config' a Proton Drive remote into duplicati-rclone/, recreate the backup job.
		- Uptime Kuma: recreate monitors + ntfy notification.
		- Then: cd $REPO_DIR && docker compose up -d   (to pick up the new .env values)
	EOF
fi
echo "- Tailscale admin: register dnsmasq ($TS_IP) as the nameserver for the 'home' search domain."
echo "- Devices: trust Caddy's local root CA for *.home HTTPS (unchanged if caddy_data was restored)."
echo "=========================================================="

finish "Media server setup complete."

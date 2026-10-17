#!/usr/bin/env bash
# ===============================================
# New Drive Watcher + Setup Wizard
# ===============================================
# Runs in the background for the whole graphical session (started by the
# drive-watcher.service systemd user unit -- see
# install/desktop/drive-watcher.sh) and watches udev for new whole-disk
# block devices: internal SSDs/HDDs present at boot, or anything hot-plugged
# later. When it finds a drive that isn't already in use, it opens a terminal
# running this same script in `setup` mode: a gum wizard that walks through
# partitioning, formatting and mounting it (via a UUID-based /etc/fstab
# entry, so it comes back on every boot).
#
# A drive counts as "in use" -- and is never offered -- if any of its
# filesystems is mounted, shares a UUID with a mounted filesystem (e.g. the
# second disk of a multi-device btrfs pool like /mnt/data, which never shows
# a mountpoint of its own), or is already referenced in /etc/fstab.
# Removable media (USB sticks, SD cards) and virtual devices (zram, loop)
# are skipped too; udisks/DMS already handle those.
#
# Choosing "Ignore" in the wizard remembers the drive (by serial/WWN, not
# /dev name -- those can flip between boots) in
# $XDG_STATE_HOME/drive-watcher/ignored-drives. Delete a line there to be
# asked about that drive again.
#
# Usage:
#   drive-watcher.sh                 # watch for new drives (the service runs this)
#   drive-watcher.sh setup /dev/sdX  # run the setup wizard for one drive
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/drive-watcher.log"
init_log "$LOG_FILE"

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
STATE_DIR="${XDG_STATE_HOME}/drive-watcher"
IGNORED_FILE="${STATE_DIR}/ignored-drives"
WINDOW_CLASS="drive-setup"

mkdir -p "$STATE_DIR"
touch "$IGNORED_FILE"

# -------------------------------------------------------------
# --- Shared helpers ---
# -------------------------------------------------------------

# Stable identity for a disk: serial, then WWN, then physical path.
drive_key() {
	local dev="$1" props key="" field
	props="$(udevadm info --query=property --name="$dev" 2>/dev/null || true)"
	for field in ID_SERIAL ID_WWN ID_PATH; do
		key="$(sed -n "s/^${field}=//p" <<<"$props" | head -n1)"
		[[ -n "$key" ]] && break
	done
	echo "${key:-$(basename "$dev")}"
}

drive_model() {
	local model
	model="$(lsblk -dno MODEL "$1" 2>/dev/null | sed 's/[[:space:]]*$//')"
	echo "${model:-Unknown drive}"
}

is_ignored() {
	grep -qxF "$1" "$IGNORED_FILE"
}

# Is this disk (or any of its partitions) mounted, part of a mounted
# multi-device filesystem, held by LVM/RAID/LUKS, or listed in /etc/fstab?
drive_in_use() {
	local dev="$1" uuid mounted_uuids

	# Any mountpoint on the disk or its partitions (one column at a time:
	# `read` collapses the empty fields lsblk prints for blank columns).
	[[ -n "$(lsblk -rno MOUNTPOINTS "$dev" 2>/dev/null | tr -d '[:space:]')" ]] && return 0
	# Held by LVM / mdraid / LUKS mappings.
	lsblk -rno TYPE "$dev" 2>/dev/null | grep -qvE '^(disk|part)$' && return 0

	mounted_uuids="$(lsblk -rno UUID,MOUNTPOINTS 2>/dev/null | awk 'NF == 2 { print $1 }')"
	while IFS= read -r uuid; do
		[[ -n "$uuid" ]] || continue
		grep -qxF "$uuid" <<<"$mounted_uuids" && return 0
		grep -Eq "^[[:space:]]*UUID=\"?${uuid}\"?[[:space:]]" /etc/fstab && return 0
	done < <(lsblk -rno UUID "$dev" 2>/dev/null)

	return 1
}

# -------------------------------------------------------------
# --- Watch mode ---
# -------------------------------------------------------------

# Drives already offered this session ("Not now" means: ask again next boot
# or next time it's plugged in, not every few seconds).
declare -A PROMPTED=()
# /dev name -> drive key, so a `remove` event can clear PROMPTED.
declare -A NAME_TO_KEY=()

launch_terminal() {
	local term="${TERMINAL:-}"
	if [[ -z "$term" ]] || ! has_cmd "$term"; then
		term=""
		for candidate in alacritty kitty ghostty wezterm foot; do
			has_cmd "$candidate" && { term="$candidate"; break; }
		done
	fi
	[[ -n "$term" ]] || { log "No terminal emulator found; cannot open setup wizard for $*"; return 1; }

	log "Opening ${term} for: $*"
	case "$term" in
	alacritty) setsid -f alacritty --class "$WINDOW_CLASS" --title "New Drive Setup" -e "$@" ;;
	kitty) setsid -f kitty --class "$WINDOW_CLASS" --title "New Drive Setup" "$@" ;;
	ghostty) setsid -f ghostty --class="com.${WINDOW_CLASS}" --title="New Drive Setup" -e "$@" ;;
	wezterm) setsid -f wezterm start --class "$WINDOW_CLASS" -- "$@" ;;
	foot) setsid -f foot --app-id "$WINDOW_CLASS" --title "New Drive Setup" "$@" ;;
	*) setsid -f "$term" -e "$@" ;;
	esac
}

check_drive() {
	local dev="$1" name key rm ro type
	name="$(basename "$dev")"

	case "$name" in
	loop* | zram* | ram* | sr* | md* | dm-*) return 0 ;;
	esac
	[[ -b "$dev" ]] || return 0

	IFS=' ' read -r type rm ro < <(lsblk -dno TYPE,RM,RO "$dev" 2>/dev/null) || return 0
	[[ "$type" == "disk" && "$rm" == "0" && "$ro" == "0" ]] || return 0

	key="$(drive_key "$dev")"
	NAME_TO_KEY["$name"]="$key"

	[[ -n "${PROMPTED[$key]:-}" ]] && return 0
	is_ignored "$key" && return 0
	drive_in_use "$dev" && return 0

	log "New drive detected: ${dev} ($(drive_model "$dev"), key=${key})"
	PROMPTED["$key"]=1
	launch_terminal bash "$SELF" setup "$dev" || true
}

watch_drives() {
	log "drive-watcher started (pid $$)"

	# Start listening before the initial scan so nothing plugged in between
	# the two is missed.
	exec 3< <(udevadm monitor --udev --subsystem-match=block/disk)

	udevadm settle --timeout=30 || true
	while IFS= read -r dev; do
		check_drive "$dev"
	done < <(lsblk -dpno NAME)

	local tag action devpath name
	while IFS=' ' read -r -u 3 tag _ action devpath _; do
		[[ "$tag" == "UDEV" ]] || continue
		name="$(basename "$devpath")"
		case "$action" in
		add)
			# Let the kernel read the partition table and udisks finish any
			# automount before deciding whether the drive is in use.
			sleep 2
			udevadm settle --timeout=10 || true
			check_drive "/dev/${name}"
			;;
		remove)
			if [[ -n "${NAME_TO_KEY[$name]:-}" ]]; then
				unset "PROMPTED[${NAME_TO_KEY[$name]}]"
				unset "NAME_TO_KEY[$name]"
				log "Drive removed: /dev/${name}"
			fi
			;;
		esac
	done
}

# -------------------------------------------------------------
# --- Setup wizard mode ---
# -------------------------------------------------------------

pause_and_exit() {
	local code="${1:-0}"
	echo
	gum style --foreground 244 "Press Enter to close this window."
	read -r _ || true
	exit "$code"
}

# fail_message (lib.sh) exits immediately, which would close the terminal
# before the error can be read -- keep the window open instead.
wizard_fail() {
	log "FAIL: $1"
	style_message 196 "$1"
	pause_and_exit 1
}

available_filesystems() {
	has_cmd mkfs.btrfs && echo "btrfs"
	has_cmd mkfs.ext4 && echo "ext4"
	has_cmd mkfs.xfs && echo "xfs"
	has_cmd mkfs.exfat && echo "exfat"
	return 0
}

fs_description() {
	case "$1" in
	btrfs) echo "btrfs  -- snapshots + compression (matches the rest of this system)" ;;
	ext4) echo "ext4   -- simple, rock-solid Linux filesystem" ;;
	xfs) echo "xfs    -- fast for large files" ;;
	exfat) echo "exfat  -- readable from Windows/macOS too" ;;
	esac
}

fstab_options() {
	# nofail + a short device timeout so a missing/dead drive can never gate
	# boot (same reasoning as /mnt/data in partition-schema.md).
	local base="nofail,x-systemd.device-timeout=10s"
	case "$1" in
	btrfs) echo "noatime,compress=zstd:1,${base}" ;;
	exfat) echo "defaults,noatime,uid=$(id -u),gid=$(id -g),umask=022,${base}" ;;
	*) echo "defaults,noatime,${base}" ;;
	esac
}

fsck_pass() {
	[[ "$1" == "ext4" ]] && echo 2 || echo 0
}

label_max_len() {
	case "$1" in
	xfs) echo 12 ;;
	exfat) echo 11 ;;
	*) echo 16 ;;
	esac
}

# Prompt for a mountpoint until a usable one is given.
ask_mountpoint() {
	local default="$1" taken="$2" mp
	while true; do
		mp="$(gum input --header "Mount point" --value "$default" --placeholder "/mnt/storage")"
		mp="${mp%/}"
		if [[ "$mp" != /* || "$mp" == "/" ]]; then
			warn_message "Mount point must be an absolute path other than /." >&2
		elif mountpoint -q "$mp" 2>/dev/null; then
			warn_message "${mp} is already a mount point." >&2
		elif awk -v mp="$mp" '$1 !~ /^#/ && $2 == mp { found=1 } END { exit !found }' /etc/fstab; then
			warn_message "${mp} is already used in /etc/fstab." >&2
		elif grep -qxF "$mp" <<<"$taken"; then
			warn_message "${mp} is already assigned to another partition in this plan." >&2
		elif [[ -e "$mp" && ! -d "$mp" ]]; then
			warn_message "${mp} exists and is not a directory." >&2
		elif [[ -d "$mp" && -n "$(ls -A "$mp" 2>/dev/null)" ]]; then
			warn_message "${mp} is not empty." >&2
		else
			echo "$mp"
			return 0
		fi
	done
}

ask_label() {
	local fs="$1" default="$2" max label
	max="$(label_max_len "$fs")"
	while true; do
		label="$(gum input --header "Filesystem label (max ${max} chars, letters/digits/-/_)" --value "$default")"
		if [[ "$label" =~ ^[A-Za-z0-9_-]{1,}$ && ${#label} -le $max ]]; then
			echo "$label"
			return 0
		fi
		warn_message "Invalid label." >&2
	done
}

# Adds a UUID-based fstab entry, mounts it, and hands it to the user.
add_fstab_and_mount() {
	local part="$1" fs="$2" mp="$3" uuid opts
	uuid="$(sudo blkid -s UUID -o value "$part")"
	[[ -n "$uuid" ]] || wizard_fail "Could not read the UUID of ${part}."

	opts="$(fstab_options "$fs")"
	sudo mkdir -p "$mp"
	printf '\n# %s (%s) -- added by drive-watcher.sh\nUUID=%s  %s  %s  %s  0 %s\n' \
		"$(drive_model "$DEV")" "$DRIVE_KEY" "$uuid" "$mp" "$fs" "$opts" "$(fsck_pass "$fs")" \
		| sudo tee -a /etc/fstab >/dev/null
	log "Added fstab entry: UUID=${uuid} ${mp} ${fs} ${opts}"

	if ! sudo findmnt --verify --tab-file /etc/fstab &>/dev/null; then
		sudo cp "$FSTAB_BACKUP" /etc/fstab
		wizard_fail "/etc/fstab failed verification after adding ${mp}; restored the backup."
	fi

	sudo systemctl daemon-reload
	sudo mount "$mp" || wizard_fail "Failed to mount ${part} at ${mp}. The fstab entry is in place -- check 'journalctl -xe'."

	[[ "$fs" == "exfat" ]] || sudo chown "$(id -u):$(id -g)" "$mp"
	okay_message "Mounted ${part} at ${mp}."
}

backup_fstab() {
	FSTAB_BACKUP="/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"
	sudo cp /etc/fstab "$FSTAB_BACKUP"
	info_message "Backed up /etc/fstab to ${FSTAB_BACKUP}."
}

wizard_format() {
	local -a fss=() specs=()
	local layout fs label mp size_in size_bytes size_mib count=0 taken="" free_mib disk_mib used_mib=0
	mapfile -t fss < <(available_filesystems)
	[[ ${#fss[@]} -gt 0 ]] || wizard_fail "No supported mkfs tools found (install btrfs-progs, e2fsprogs, xfsprogs or exfatprogs)."
	has_cmd parted || wizard_fail "parted is required. Install it with: sudo dnf install -y parted"

	disk_mib=$(($(lsblk -bdno SIZE "$DEV") / 1024 / 1024))
	# 1 MiB alignment gap at the start, plus room for the backup GPT at the end.
	free_mib=$((disk_mib - 2))

	layout="$(gum choose --header "Partition layout" \
		"One partition using the whole drive" \
		"Multiple partitions")"

	while true; do
		count=$((count + 1))
		echo
		gum style --foreground 212 --bold "Partition ${count}"

		size_mib=0
		if [[ "$layout" == "Multiple partitions" ]]; then
			while true; do
				info_message "$(numfmt --to=iec-i --suffix=B $(((free_mib - used_mib) * 1024 * 1024))) unallocated."
				size_in="$(gum input --header "Size (e.g. 500G, 1.5T) -- leave empty to use all remaining space" --placeholder "remaining space")"
				[[ -z "$size_in" ]] && break
				size_in="${size_in%[Bb]}"
				size_in="${size_in%[Ii]}"
				size_bytes="$(numfmt --from=iec "${size_in^^}" 2>/dev/null || true)"
				if [[ "$size_bytes" =~ ^[0-9]+$ ]]; then
					size_mib=$((size_bytes / 1024 / 1024))
					((size_mib > 0 && used_mib + size_mib <= free_mib)) && break
				fi
				warn_message "Invalid size, or larger than the remaining space."
				size_mib=0
			done
		fi

		fs="$(for f in "${fss[@]}"; do fs_description "$f"; done | gum choose --header "Filesystem")"
		fs="${fs%% *}"
		label="$(ask_label "$fs" "$( ((count == 1)) && echo storage || echo "storage${count}")")"
		mp="$(ask_mountpoint "/mnt/${label,,}" "$taken")"
		taken+="${mp}"$'\n'

		specs+=("${size_mib}|${fs}|${label}|${mp}")

		if ((size_mib == 0)); then
			used_mib=$free_mib
			break
		fi
		used_mib=$((used_mib + size_mib))
		((free_mib - used_mib < 1)) && break
		gum confirm "Add another partition?" || break
	done

	# --- Review + confirm ---
	local plan
	plan="Drive:  ${DEV}  ($(drive_model "$DEV"), $(lsblk -dno SIZE "$DEV" | tr -d ' '))"$'\n'
	plan+="Table:  GPT (everything currently on the drive will be ERASED)"$'\n\n'
	local i=1 spec
	for spec in "${specs[@]}"; do
		IFS='|' read -r size_mib fs label mp <<<"$spec"
		local size_str="rest of drive"
		((size_mib > 0)) && size_str="$(numfmt --to=iec-i --suffix=B $((size_mib * 1024 * 1024)))"
		plan+="  ${i}. ${size_str}  ${fs}  label=${label}  -> ${mp}"$'\n'
		i=$((i + 1))
	done
	echo
	gum style --border rounded --padding "1 2" --border-foreground 214 "$plan"

	gum confirm --default=false "Erase ${DEV} and apply this plan?" || { info_message "Cancelled -- nothing was changed."; pause_and_exit 0; }
	local typed
	typed="$(gum input --header "Type the drive name ($(basename "$DEV")) to confirm" --placeholder "$(basename "$DEV")")"
	[[ "$typed" == "$(basename "$DEV")" ]] || { warn_message "Name didn't match -- nothing was changed."; pause_and_exit 0; }

	# --- Do it ---
	info_message "Enter your sudo password if prompted..."
	sudo -v || wizard_fail "sudo authentication failed."
	drive_in_use "$DEV" && wizard_fail "${DEV} is now in use (mounted or in fstab) -- refusing to touch it."

	backup_fstab

	spinner "Wiping existing signatures on ${DEV}..." sudo wipefs --all --force "$DEV" \
		|| wizard_fail "wipefs failed on ${DEV}."
	spinner "Creating GPT partition table..." sudo parted --script "$DEV" mklabel gpt \
		|| wizard_fail "Failed to create a partition table on ${DEV}."

	local start=1 end n=1
	for spec in "${specs[@]}"; do
		IFS='|' read -r size_mib fs label mp <<<"$spec"
		if ((size_mib == 0)); then end="100%"; else end="$((start + size_mib))MiB"; fi
		spinner "Creating partition ${n}..." sudo parted --script --align optimal "$DEV" mkpart "$label" "${start}MiB" "$end" \
			|| wizard_fail "Failed to create partition ${n}."
		((size_mib > 0)) && start=$((start + size_mib))
		n=$((n + 1))
	done

	sudo partprobe "$DEV" 2>/dev/null || true
	sudo udevadm settle --timeout=30 || true

	local -a parts=()
	mapfile -t parts < <(lsblk -rpno NAME,TYPE "$DEV" | awk '$2 == "part" { print $1 }')
	[[ ${#parts[@]} -eq ${#specs[@]} ]] \
		|| wizard_fail "Expected ${#specs[@]} partition(s) on ${DEV} but found ${#parts[@]}."

	local idx part
	for idx in "${!specs[@]}"; do
		IFS='|' read -r size_mib fs label mp <<<"${specs[$idx]}"
		part="${parts[$idx]}"
		case "$fs" in
		btrfs) spinner "Formatting ${part} as btrfs..." sudo mkfs.btrfs -f -L "$label" "$part" ;;
		ext4) spinner "Formatting ${part} as ext4..." sudo mkfs.ext4 -F -L "$label" "$part" ;;
		xfs) spinner "Formatting ${part} as xfs..." sudo mkfs.xfs -f -L "$label" "$part" ;;
		exfat) spinner "Formatting ${part} as exfat..." sudo mkfs.exfat -L "$label" "$part" ;;
		esac || wizard_fail "Failed to format ${part} as ${fs}."
		okay_message "Formatted ${part} (${fs}, label ${label})."
		sudo udevadm settle --timeout=10 || true
		add_fstab_and_mount "$part" "$fs" "$mp"
	done
}

wizard_mount_existing() {
	local -a choices=()
	local name fstype size label line part fs mp
	# NAME and SIZE are never blank, so `read` can't shift columns on them.
	while IFS=' ' read -r name size fstype label; do
		[[ -n "$fstype" ]] || continue
		case "$fstype" in swap | linux_raid_member | LVM2_member | crypto_LUKS) continue ;; esac
		choices+=("${name}  ${fstype}  ${size}  ${label:-<no label>}")
	done < <(lsblk -rpno NAME,SIZE,FSTYPE,LABEL "$DEV")

	[[ ${#choices[@]} -gt 0 ]] || wizard_fail "No mountable filesystems found on ${DEV}. Choose the format option instead."

	line="$(printf '%s\n' "${choices[@]}" | gum choose --header "Which filesystem should be mounted?")"
	IFS=' ' read -r part fs _ label <<<"$line"
	[[ "$label" == "<no label>" ]] && label="storage"

	mp="$(ask_mountpoint "/mnt/${label,,}" "")"

	info_message "Enter your sudo password if prompted..."
	sudo -v || wizard_fail "sudo authentication failed."
	backup_fstab
	add_fstab_and_mount "$part" "$fs" "$mp"
}

setup_wizard() {
	DEV="${1:-}"
	[[ -b "$DEV" ]] || { echo "Usage: $(basename "$0") setup /dev/sdX" >&2; exit 1; }
	ensure_gum

	DRIVE_KEY="$(drive_key "$DEV")"
	banner "New Drive Detected"

	gum style --border rounded --padding "0 2" --border-foreground 244 \
		"$(lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MODEL "$DEV")"
	echo

	if drive_in_use "$DEV"; then
		okay_message "${DEV} is already mounted or configured in /etc/fstab -- nothing to do."
		pause_and_exit 0
	fi

	local has_fs=false action
	[[ -n "$(lsblk -rno FSTYPE "$DEV" | tr -d '[:space:]')" ]] && has_fs=true
	$has_fs && warn_message "This drive already contains data."

	local -a actions=("Partition, format and mount it")
	$has_fs && actions+=("Mount an existing filesystem (keep data)")
	actions+=("Not now (ask again next boot)" "Ignore this drive (never ask again)")

	action="$(gum choose --header "What would you like to do with ${DEV}?" "${actions[@]}")" || action="Not now"

	case "$action" in
	"Partition, format"*) wizard_format ;;
	"Mount an existing"*) wizard_mount_existing ;;
	"Ignore"*)
		echo "$DRIVE_KEY" >>"$IGNORED_FILE"
		log "Ignoring drive ${DRIVE_KEY}"
		info_message "Won't ask about this drive again. Remove '${DRIVE_KEY}' from ${IGNORED_FILE} to undo."
		pause_and_exit 0
		;;
	*)
		info_message "Okay -- you'll be asked again next boot."
		pause_and_exit 0
		;;
	esac

	finish_text="Drive setup complete!"$'\n\n'"$(lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$DEV")"
	log "FINISH: drive setup complete for ${DEV}"
	gum style --border normal --margin "1" --padding "1" --foreground 120 "$finish_text"
	pause_and_exit 0
}

# -------------------------------------------------------------
# --- Entry point ---
# -------------------------------------------------------------

case "${1:-watch}" in
watch) watch_drives ;;
setup) setup_wizard "${2:-}" ;;
*)
	echo "Usage: $(basename "$0") [watch | setup /dev/sdX]" >&2
	exit 1
	;;
esac

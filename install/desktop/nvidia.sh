#!/usr/bin/env bash
# ===============================================
# NVIDIA Driver Installation
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"

readonly LOG_FILE="${LOG_DIR}/install-nvidia.log"
init_log "$LOG_FILE"

ensure_gum

banner "NVIDIA Driver and RPMFusion Setup"

# -------------------------------------------------------
# Helper: detect_nvidia_gpu
#   Prints the full lspci line for the first NVIDIA GPU
#   found (VGA or 3D controller), or empty string if none.
# -------------------------------------------------------
detect_nvidia_gpu() {
    if ! has_cmd lspci; then
        warn_message "'lspci' not found. Installing pciutils..."
        sudo dnf install -y pciutils >/dev/null 2>&1 \
            || fail_message "Failed to install pciutils. Cannot scan hardware."
    fi

    local gpu_line
    gpu_line=$(lspci | grep -iE 'VGA compatible controller|3D controller' | grep -i 'NVIDIA' || true)
    echo "$gpu_line"
}

# -------------------------------------------------------
# Helper: map_gpu_to_driver
#   Maps the lspci GPU description to the correct RPMFusion
#   akmod package name.
#
#   RPMFusion driver support matrix (as of early 2025):
#
#   akmod-nvidia         Turing (GTX 1600/RTX 2000+) and newer
#                        Compute 7.x+
#                        GeForce GTX 16xx, RTX 20xx, 30xx, 40xx, 50xx
#
#   akmod-nvidia-580xx   Maxwell (GTX 750/900) and Pascal (GTX 1000)
#                        Compute 5.x (Maxwell) and 6.x (Pascal)
#                        GeForce GTX 750, 750 Ti, 900 series, 1000 series
#                        Dropped from current driver in 2024
#
#   akmod-nvidia-470xx   Kepler (GTX 600/700)
#                        Compute 3.x
#                        GeForce GTX 6xx, 7xx; Tesla K; Quadro Kx
#
#   akmod-nvidia-390xx   Fermi (GTX 400/500)
#                        Compute 2.x — EOL, no security fixes upstream
#                        GeForce GTX 4xx, 5xx; Tesla C/F; old Quadros
# -------------------------------------------------------
map_gpu_to_driver() {
    local gpu_line="$1"
    local lower
    lower=$(echo "$gpu_line" | tr '[:upper:]' '[:lower:]')

    # --- Turing and newer (RTX 2000, RTX 3000, RTX 4000, RTX 5000, GTX 1600 series) ---
    # Turing: GTX 1650, 1660, RTX 2060-2080
    # Ampere: RTX 3060-3090
    # Ada Lovelace: RTX 4060-4090
    # Blackwell: RTX 5070-5090
    if echo "$lower" | grep -qE \
        'gtx 16[5-9][0-9]|rtx 20[0-9]{2}|rtx 30[0-9]{2}|rtx 40[0-9]{2}|rtx 50[0-9]{2}'; then
        echo "akmod-nvidia"
        return
    fi

    # --- Pascal (GTX 1000 series, Compute 6.x) ---
    # GTX 1050, 1060, 1070, 1080, Titan X/Xp, Tesla P
    if echo "$lower" | grep -qE \
        'gtx 10[0-9]{2}|titan x[p]?|tesla p[0-9]|quadro p[0-9]'; then
        echo "akmod-nvidia-580xx"
        return
    fi

    # --- Maxwell (GTX 750 and 900 series, Compute 5.x) ---
    # GTX 750, 750 Ti (GM107), GTX 950–980 Ti (GM2xx), Titan X (Maxwell)
    # Tesla M, Quadro Mxxx
    if echo "$lower" | grep -qE \
        'gtx 750|gtx 9[0-9]{2}|titan x |tesla m[0-9]|quadro m[0-9]'; then
        echo "akmod-nvidia-580xx"
        return
    fi

    # --- Kepler (GTX 600/700 series, Compute 3.x) ---
    # GTX 6xx, GTX 7xx (non-750), Tesla K, Quadro Kx
    if echo "$lower" | grep -qE \
        'gtx [67][0-9]{2}|tesla k[0-9]|quadro k[0-9]'; then
        echo "akmod-nvidia-470xx"
        return
    fi

    # --- Fermi (GTX 400/500 series, Compute 2.x) ---
    # GTX 4xx, GTX 5xx, Tesla C/F, old Quadros
    if echo "$lower" | grep -qE \
        'gtx [45][0-9]{2}|tesla [cf][0-9]|quadro [0-9]{4}m?$'; then
        echo "akmod-nvidia-390xx"
        return
    fi

    # --- Unknown / very new / very old ---
    # Default to current driver; user can override.
    warn_message "GPU generation could not be identified from: $gpu_line"
    warn_message "Defaulting to current 'akmod-nvidia'. Override manually if incorrect."
    echo "akmod-nvidia"
}

# -------------------------------------------------------
# STEP 1: Scan hardware for an NVIDIA GPU
# -------------------------------------------------------

info_message "Scanning hardware for an NVIDIA GPU..."

GPU_LINE=$(detect_nvidia_gpu)

if [[ -z "$GPU_LINE" ]]; then
    info_message "No NVIDIA GPU detected on this system."
    info_message "Skipping NVIDIA driver installation."
    finish "NVIDIA setup complete (no GPU found)."
fi

# GPU found — display it
okay_message "NVIDIA GPU detected:"
gum style --foreground 212 "  ${GPU_LINE}"
echo ""

DRIVER_PKG=$(map_gpu_to_driver "$GPU_LINE")
info_message "Recommended RPMFusion driver package: ${DRIVER_PKG}"

# Explain the choice to the user
case "$DRIVER_PKG" in
    "akmod-nvidia")
        info_message "This is the current driver — supports Turing (GTX 1600/RTX 2000) and newer GPUs."
        ;;
    "akmod-nvidia-580xx")
        info_message "This is the 580xx legacy driver — supports Maxwell (GTX 750/900) and Pascal (GTX 1000) GPUs."
        warn_message "Your GPU was dropped from the current driver in 2024. The 580xx driver is the latest supported version."
        ;;
    "akmod-nvidia-470xx")
        info_message "This is the 470xx legacy driver — supports Kepler (GTX 600/700) GPUs."
        warn_message "Kepler support is in long-term maintenance mode. Security fixes only."
        ;;
    "akmod-nvidia-390xx")
        warn_message "This is the 390xx driver — supports Fermi (GTX 400/500) GPUs."
        warn_message "Fermi support is END OF LIFE upstream. No security fixes are being made."
        warn_message "Consider upgrading your GPU."
        ;;
esac
echo ""

# -------------------------------------------------------
# STEP 2: Add RPMFusion repositories (only if not already present)
# -------------------------------------------------------

if dnf repolist enabled 2>/dev/null | grep -q 'rpmfusion'; then
    info_message "RPMFusion repositories are already configured. Skipping."
else
    fedora_ver=$(rpm -E %fedora)

    spinner "Adding RPMFusion free and nonfree repositories..." \
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

    spinner "Refreshing package metadata after adding RPMFusion..." \
        sudo dnf update -y

    okay_message "RPMFusion repositories configured."
fi

# -------------------------------------------------------
# STEP 3: Offer driver installation
# -------------------------------------------------------

if gum confirm "Install NVIDIA drivers (${DRIVER_PKG}) from RPMFusion?"; then
    # The 580xx and 470xx legacy packages do not ship the CUDA xorg driver
    cuda_pkg=""
    if [[ "$DRIVER_PKG" == "akmod-nvidia" ]]; then
        cuda_pkg="xorg-x11-drv-nvidia-cuda"
    fi

    spinner "Installing ${DRIVER_PKG} and Vulkan dependencies..." \
        sudo dnf install -y \
            "${DRIVER_PKG}" \
            ${cuda_pkg:+"$cuda_pkg"} \
            vulkan-loader \
            vulkan-loader.i686 \
        || fail_message "Failed to install NVIDIA drivers. Check ${LOG_FILE} for details."

    okay_message "NVIDIA drivers installed successfully."
    warn_message "The akmod kernel module will compile on the first reboot."
    warn_message "Do not force-power-off during that boot — akmods needs time to compile."

    if [[ "$DRIVER_PKG" == "akmod-nvidia-390xx" ]]; then
        warn_message "Fermi (390xx) note: Wayland is NOT supported. Use Xorg only."
    fi
else
    info_message "NVIDIA driver installation skipped by user."
fi

finish "NVIDIA driver installation step complete."
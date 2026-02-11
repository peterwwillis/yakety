#!/usr/bin/env sh

# This script installs all required dependencies for building Yakety on Linux

set -e
[ "${DEBUG:-0}" = "1" ] && set -x

echo "=== Installing Linux Dependencies for Yakety ==="
echo ""


SUDO="sudo"


$SUDO apt-get update

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get install -y --no-install-recommends software-properties-common

$SUDO add-apt-repository universe

$SUDO apt-get update

$SUDO apt-get install -y --no-install-recommends \
    ninja-build \
    pkg-config \
    libasound2-dev \
    libpulse-dev \
    libomp-dev \
    libevdev-dev \
    glslc \
    libvulkan-dev \
    vulkan-tools \
    curl \
    wget \
    xclip \
    xdotool \
    zenity \
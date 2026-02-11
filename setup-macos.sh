#!/usr/bin/env sh

# This script installs all required dependencies for building Yakety on macOS

set -e
[ "${DEBUG:-0}" = "1" ] && set -x

echo "=== Installing macOS Dependencies for Yakety ==="
echo ""

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH if needed
    if [ -f "$HOME/.bashrc" ]; then
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    fi
else
    echo "Homebrew found"
fi

# Install build tools
echo "Installing build tools..."
brew install cmake ninja

# Install audio libraries
echo "Installing audio libraries..."
brew install openal-soft

# Install GPU-related libraries
echo "Installing GPU/Vulkan libraries..."
brew install vulkan-headers vulkan-loader molten-vk shaderc

# Ensure Xcode Command Line Tools are installed
echo "Checking for Xcode Command Line Tools..."
if ! command -v clang &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || true
fi

# Optional: Install additional development tools
echo "Installing optional development tools..."
brew install git curl wget pkg-config

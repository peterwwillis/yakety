# Yakety

Cross-platform instant voice-to-text application. Hold a key, speak, release to paste transcribed text at cursor.

## Features

- **Instant transcription**: Hold Right Ctrl (Windows/Linux) or Fn (macOS), speak, release to paste
- **Local AI processing**: Uses OpenAI Whisper running locally - no internet required
- **Cross-platform**: Native apps for Windows, macOS, and Linux
- **Minimal UI**: Small overlay shows recording status
- **System integration**: Menu bar (macOS) or system tray (Windows/Linux)

## Build Instructions

### Windows Build Requirements

1. **Visual Studio 2022** (Community Edition is free)
   - Download: https://visualstudio.microsoft.com/downloads/
   - During installation, select "Desktop development with C++"
   - Includes MSVC compiler and Windows SDK

2. **CMake** (3.20 or newer)
   - Download: https://cmake.org/download/
   - Choose "Add CMake to system PATH" during installation

3. **Git for Windows**
   - Download: https://git-scm.com/download/win
   - Required for cloning the repository

4. **Vulkan SDK** (Optional - for GPU acceleration)
   - Download: https://vulkan.lunarg.com/sdk/home#windows
   - Provides 2-5x faster transcription on compatible GPUs

### Linux Build Requirements

1. **Build Tools**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install build-essential cmake git

   # Fedora
   sudo dnf install gcc gcc-c++ make cmake git

   # Arch
   sudo pacman -S base-devel cmake git
   ```

2. **Audio Libraries**
   ```bash
   # Ubuntu/Debian
   sudo apt install libasound2-dev libpulse-dev

   # Fedora
   sudo dnf install alsa-lib-devel pulseaudio-libs-devel

   # Arch
   sudo pacman -S alsa-lib pulse
   ```

3. **X11 Development Libraries**
   ```bash
   # Ubuntu/Debian
   sudo apt install libx11-dev libxtst-dev

   # Fedora
   sudo dnf install libX11-devel libXtst-devel

   # Arch
   sudo pacman -S libx11 libxtst
   ```

4. **Vulkan SDK** (Optional - for GPU acceleration)
   ```bash
   # Ubuntu/Debian
   wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
   sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list
   sudo apt update
   sudo apt install vulkan-sdk

   # Other distros: Download from https://vulkan.lunarg.com/sdk/home#linux
   ```

### Build Steps

```bash
# Clone repository
git clone https://github.com/badlogic/yakety
cd yakety

# Windows
build.bat
# Executables will be in build\bin\
# - yakety.exe (CLI version)
# - yakety-app.exe (GUI version with system tray)

# Linux
chmod +x build.sh
./build.sh
# Executables will be in build/bin/
# - yakety (CLI version)
# - yakety-app (GUI version with system tray)

# macOS
./build.sh
# Creates Yakety.app in dist/
```

### First Run

1. **Windows**: Run as Administrator (required for global hotkeys)
   ```
   Right-click yakety-app.exe → Run as administrator
   ```

2. **Linux**: May need to add user to input group for global hotkeys
   ```bash
   sudo usermod -a -G input $USER
   # Log out and back in for changes to take effect
   ```

3. **All platforms**: The Whisper AI model (~150MB) will be downloaded on first run

## System Requirements

### Minimum Requirements
- **CPU**: x64 processor with AVX2 support (Intel Haswell 2013+ / AMD Excavator 2015+)
- **RAM**: 4GB (8GB recommended)
- **Storage**: 500MB free space
- **OS**: 
  - Windows 10/11 (64-bit)
  - macOS 10.15+
  - Linux with X11 (Wayland support planned)

### GPU Acceleration (Optional)
- **NVIDIA**: GTX 600+ with CUDA support
- **AMD**: Radeon HD 7000+ with Vulkan support
- **Intel**: HD Graphics 4400+ or Arc with Vulkan support

## Troubleshooting

### Windows Issues

**"Cannot open windows.h" during build**
- Ensure Visual Studio is installed with C++ desktop development workload
- Run build from Developer Command Prompt for VS 2022

**"Administrator privileges required"**
- Right-click the .exe and select "Run as administrator"
- Required for global keyboard monitoring

**Build fails with "... was unexpected at this time"**
- Update to latest version - this was fixed in recent commits

### Linux Issues

**"Cannot detect key presses"**
```bash
# Add user to input group
sudo usermod -a -G input $USER
# Log out and back in
```

**"No audio devices found"**
```bash
# Install PulseAudio or ALSA
sudo apt install pulseaudio
# or
sudo apt install alsa-base alsa-utils
```

**Build fails with missing dependencies**
- Check that all development packages are installed (see Linux Build Requirements)

### General Issues

**Model download is slow**
- The build script now uses curl for faster downloads
- Alternatively, manually download from: https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
- Place in `whisper.cpp/models/` directory

**Poor transcription quality**
- Speak clearly and at normal pace
- Reduce background noise
- Consider using a better microphone
- GPU acceleration can improve accuracy

## Build Artifacts

- `yakety` - CLI version for terminal use
- `yakety-app` - GUI app with menu bar/system tray
- `recorder` - Standalone audio recording utility
- `test_transcription` - Whisper integration test
- `ggml-base.en.bin` - Whisper AI model (~150MB, auto-downloaded)

### Platform Packages
- **macOS**: `dist/Yakety.app` - Self-contained app bundle
- **Windows**: `dist/yakety.exe` + `dist/yakety-app.exe` - Standalone executables

## Architecture

### Core Components
- `src/audio.c/h` - Cross-platform audio capture (miniaudio)
- `src/transcription.cpp/h` - Whisper AI integration
- `src/keylogger.c` - Global hotkey monitoring
- `src/overlay.h` - Recording/transcribing visual feedback
- `src/menubar.h` - System tray/menu bar interface

### Platform-Specific
- `src/mac/` - macOS implementations (Objective-C)
  - `main.m` - CLI entry point
  - `main_app.m` - GUI app entry point
  - `menubar.m` - macOS menu bar
  - `overlay.m` - macOS overlay window
  - `audio_permissions.m` - macOS permission handling

- `src/windows/` - Windows implementations (Win32)
  - `main.c` - CLI entry point
  - `main_app.c` - GUI app entry point
  - `menubar.c` - Windows system tray
  - `overlay.c` - Windows overlay window
  - `keylogger.c` - Windows keyboard hooks
  - `clipboard.c` - Windows clipboard handling

### External Dependencies
- `whisper.cpp/` - Local AI speech recognition (submodule)
- `src/miniaudio.h` - Audio library (header-only)

### Build System
- `CMakeLists.txt` - Main build configuration
- `build.sh` - macOS build script
- `build.bat` - Windows build script
- `build-windows.sh` - Cross-compile for Windows from macOS
- `package.sh` - macOS app bundle packaging
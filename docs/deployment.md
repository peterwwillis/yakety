# Deployment Documentation

<!-- Generated: 2025-06-14 18:30:00 UTC -->

## Overview

Yakety features a comprehensive packaging and distribution system supporting both CLI and GUI applications across macOS and Windows platforms. The deployment system is automated through CMake targets and shell scripts, handling everything from code signing to server uploads.

## Package Types

### CLI Distribution

**macOS CLI Package** (`package-cli-macos` target):
- **Build command**: `cmake --build build --target package-cli-macos`
- **Output**: `build/yakety-cli-macos.zip`
- **Contents**:
  - `bin/yakety-cli` - Main CLI executable
  - `bin/models/ggml-base-q8_0.bin` - Whisper model (CMakeLists.txt:162, 278-285)
  - `bin/menubar.png` - Menubar icon (CMakeLists.txt:288-298)
  - `bin/recorder` - Audio recording utility
  - `bin/transcribe` - Transcription utility

**Windows CLI Package** (`package-cli-windows` target):
- **Build command**: `cmake --build build --target package-cli-windows`
- **Output**: `build/yakety-cli-windows.zip`
- **Contents**: Same as macOS but with `.exe` extensions (CMakeLists.txt:421-433)

### App Distribution

**macOS App Package** (`package-app-macos` target):
- **Build command**: `cmake --build build --target package-app-macos`
- **Outputs**:
  - `build/Yakety-macos.dmg` - DMG installer
  - `build/Yakety-macos.zip` - Compressed DMG
- **Bundle configuration**: `src/mac/Info.plist` with bundle ID `com.yakety.app`
- **Resources embedded** (CMakeLists.txt:158-183):
  - `assets/yakety.icns` - App icon
  - `assets/generated/menubar.png` - Menu bar icon
  - `whisper.cpp/models/ggml-base-q8_0.bin` - Whisper model

**Windows App Package** (`package-app-windows` target):
- **Build command**: `cmake --build build --target package-app-windows`
- **Output**: `build/Yakety-windows.zip`
- **Executable**: `Yakety.exe` (GUI application, no console window)
- **Resources**: `src/windows/yakety.rc` with embedded icon and version info

## Platform Deployment

### macOS Deployment

**App Bundle Configuration** (CMakeLists.txt:142-186):
```cmake
add_executable(yakety-app MACOSX_BUNDLE
    src/main.c
    ${BUSINESS_SOURCES}
)

set_target_properties(yakety-app PROPERTIES
    OUTPUT_NAME "Yakety"
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/src/mac/Info.plist
    MACOSX_BUNDLE_BUNDLE_NAME "Yakety"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.yakety.app"
)
```

**Code Signing Process**:
1. **Automatic signing** during build (cmake/PlatformSetup.cmake:85-94):
   ```cmake
   add_custom_command(TARGET ${target} POST_BUILD
       COMMAND codesign --force --deep --sign - "$<TARGET_BUNDLE_DIR:${target}>"
       COMMAND xattr -cr "$<TARGET_BUNDLE_DIR:${target}>"
   )
   ```

2. **Manual signing script** (`sign-app.sh`):
   ```bash
   # Ad-hoc signature for local use
   codesign --force --deep --sign - "$APP_PATH"
   codesign --verify --verbose "$APP_PATH"
   xattr -cr "$APP_PATH"
   ```

**DMG Creation Process** (CMakeLists.txt:393-410):
- Creates temporary directory with app bundle
- Adds Applications symlink for drag-and-drop installation
- Uses `hdiutil` to create compressed DMG
- Additional ZIP compression for distribution

### Windows Deployment

**Executable Configuration**:
- **GUI Application**: `WIN32` flag removes console window (CMakeLists.txt:128-140)
- **Resource file**: `src/windows/yakety.rc` embeds icon and version information
- **Output name**: `Yakety.exe` for GUI app, `yakety-cli.exe` for CLI

**Platform Libraries** (cmake/PlatformSetup.cmake:44-46):
```cmake
set(PLATFORM_LIBS winmm ole32 user32 shell32 gdi32 PARENT_SCOPE)
```

**Vulkan Support** (cmake/PlatformSetup.cmake:48-61):
- Detects Vulkan SDK from environment
- Links `vulkan-1.dll` for GPU acceleration
- Adds Vulkan library to whisper.cpp linking

### Build Configuration

**CMake Presets** (`CMakePresets.json`):
- **Release preset**: `build/` directory, Ninja generator
- **Debug preset**: `build-debug/` directory
- **Visual Studio preset**: Windows-specific debugging support

**Platform-Specific Setup** (CMakeLists.txt:17-23):
```cmake
if(APPLE)
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0")
endif()
```

## Reference

### Deployment Scripts

**Package Creation**:
- `cmake --build build --target package` - Current platform packages
- `cmake --build build --target package-macos` - All macOS packages
- `cmake --build build --target package-windows` - All Windows packages

**Server Upload** (CMakeLists.txt:492-499):
```bash
# macOS/Linux
rsync -avz --progress build/*.zip badlogic@slayer.marioslab.io:/home/badlogic/mariozechner.at/html/uploads/

# Windows
scp "build/*.zip" badlogic@slayer.marioslab.io:/home/badlogic/mariozechner.at/html/uploads/
```

### Output Locations

**Build Outputs**:
- **Executables**: `build/bin/` (CMakeLists.txt:270-275)
- **CLI packages**: `build/yakety-cli-{platform}.zip`
- **App packages**: `build/Yakety-{platform}.{dmg,zip}`
- **macOS app bundle**: `build/bin/Yakety.app`

**Website Deployment** (`website/publish.sh`):
```bash
# Frontend and backend upload
rsync -avz --delete build/ slayer.marioslab.io:/home/badlogic/yakety.ai/build/
rsync -avz --delete html/ slayer.marioslab.io:/home/badlogic/yakety.ai/html/
rsync -avz --exclude='data' docker/ slayer.marioslab.io:/home/badlogic/yakety.ai/docker/
```

### Server Configuration

**Docker Composition** (`website/docker/docker-compose.base.yml`):
- **Nginx frontend**: Serves static files and proxies API requests
- **Node.js backend**: Handles API endpoints on port 3333
- **Volume mounts**: Logs, static files, and application data

**Production Configuration** (`website/docker/docker-compose.prod.yml`):
- **SSL termination**: Let's Encrypt certificates for `yakety.ai`
- **Reverse proxy**: nginx-proxy network integration
- **Domain mapping**: `yakety.ai` and `www.yakety.ai`

**Nginx Configuration** (`website/docker/nginx.conf`):
- **API proxy**: `/api` requests to Node.js backend
- **WebSocket support**: `/ws` endpoint for live reload
- **Security headers**: CSP, XSS protection, frame options
- **Compression**: Gzip for text and JavaScript assets

**Server Control** (`website/docker/control.sh`):
- `./control.sh start` - Production deployment
- `./control.sh startdev` - Development mode
- `./control.sh logs` - Live log monitoring
- `./control.sh restart` - Full service restart
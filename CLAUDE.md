- YOU, CLAUDE, CAN NOT TEST THE PROGRAMS, ASK THE USER TO TEST AND REPORT RESULTS

# Code Style Guidelines

- Use **C-style C++**: Write C++ code but with C-style conventions
- Prefer C-style casts, function declarations, and naming conventions
- Use C++ features (std::vector, extern "C") only when required for whisper.cpp integration
- Keep the core application logic in C-style for simplicity and readability
- File extensions: .cpp for files that need C++ features, .c for pure C files

- ALWAYS USE rg NOT GREP

# CMake Build Presets

- **Normal development**: Use `cmake --preset release` or `cmake --preset debug`
  - Uses Ninja generator on all platforms for fast builds
- **Windows debugging**: Use `cmake --preset vs-debug` when you need Visual Studio for debugging
  - Uses Visual Studio 2022 generator with proper debugging support
  - Only available on Windows

# Windows/WSL Remote Development

When developing on Windows via SSH from macOS:

## Connection Setup

- Windows machine accessible at `192.168.1.21` via SSH using username `badlogic`
- Yakety workspace located at: `/mnt/c/workspaces/yakety/`
- Must run `start-wsl-ssh.bat` as administrator on Windows before connecting

## Build Process

1. **Sync changes**: Use rsync to sync only source files (excludes build/ and whisper.cpp/):

   ```bash
   rsync -av --exclude='build/' --exclude='build-debug/' --exclude='whisper.cpp/' --exclude='website/' --exclude='.git/' --exclude='.vscode/' --exclude='.claude/' . badlogic@192.168.1.21:/mnt/c/workspaces/yakety/
   ```

2. **Configure and build**: Must use cmd.exe with proper environment setup:

   ```bash
   ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && /mnt/c/Windows/System32/cmd.exe /c 'cd c:\\workspaces\\yakety && c:\\workspaces\\winvs.bat && cmake --preset release'"
   ```

3. **Build after configure**:

   ```bash
   ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && /mnt/c/Windows/System32/cmd.exe /c 'cd c:\\workspaces\\yakety && c:\\workspaces\\winvs.bat && cmake --build --preset release'"
   ```

4. **Run CLI**:
   ```bash
   ssh badlogic@192.168.1.21 "cd /mnt/c/workspaces/yakety && build/bin/yakety-cli.exe"
   ```

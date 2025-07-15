# Whisper.cpp build should use Ninja as the generator if possible
**Status:** InProgress
**Agent PID:** 12008

## Original Todo
- Whisper.cpp build should use Ninja as the generator if possible

## Description
Modify the Yakety CMake build configuration to use the Ninja generator when building the cloned whisper.cpp repository, even if the parent project uses a different generator. This involves updating BuildWhisper.cmake to detect Ninja availability and configure whisper.cpp with `-G Ninja` when possible, while falling back to the parent project's generator if Ninja is not available.

## Implementation Plan
- [ ] Update cmake/BuildWhisper.cmake to detect Ninja availability using find_program() (cmake/BuildWhisper.cmake:75-85)
- [ ] Modify whisper.cpp ExternalProject_Add to use Ninja generator when available (cmake/BuildWhisper.cmake:79)
- [ ] Update CMakeLists.txt library path detection to handle mixed generators (CMakeLists.txt:223-230)
- [ ] Test build with Ninja available
- [ ] Test build without Ninja to ensure fallback works
- [ ] User test: Clean build using ./build.sh verifies Ninja is used for whisper.cpp when available

## Notes
Since whisper.cpp is cloned during build, all changes must be made in our CMake configuration, not in the whisper.cpp repository itself.
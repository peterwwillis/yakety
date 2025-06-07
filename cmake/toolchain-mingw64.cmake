# Toolchain file for cross-compiling to Windows using MinGW-w64 on macOS

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Specify the cross compiler
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)

# Find the MinGW installation path
execute_process(
    COMMAND brew --prefix mingw-w64
    OUTPUT_VARIABLE MINGW_PREFIX
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Set the sysroot
set(CMAKE_FIND_ROOT_PATH ${MINGW_PREFIX}/toolchain-x86_64)

# Adjust the default behavior of the FIND_XXX() commands:
# search programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Set compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libgcc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")

# Windows specific defines
add_definitions(-D_WIN32_WINNT=0x0600)
add_definitions(-DWINVER=0x0600)
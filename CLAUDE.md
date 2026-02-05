# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

xbrzscale is a commandline tool for scaling pixel art images using the xBRZ algorithm (https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms#xBR_family). It supports scaling factors from 2x to 6x and outputs PNG files.

## Build Commands

### CMake (Recommended - Cross-platform)
```bash
mkdir build && cd build
cmake ..                            # Configure the build
cmake --build . --config Release    # Build the project
```

The CMake build automatically:
- Downloads and builds SDL2 and SDL2_image dependencies via FetchContent
- Copies required DLLs to the output directory on Windows
- Works with Visual Studio, MinGW, Ninja, and Unix Makefiles generators

Output files are located in `build/Release/` (or `build/` on Unix systems).

### Legacy Makefiles

#### Linux/macOS
```bash
make                # Build the xbrzscale binary
make clean          # Remove build artifacts
```

#### Windows (MinGW)
```bash
mingw32-make -f Makefile-win        # Build xbrzscale.exe
mingw32-make -f Makefile-win clean  # Remove build artifacts
```

**Note:** Legacy Makefiles require SDL2 libraries to be pre-installed on the system.

## Dependencies

Required libraries:
- **libsdl2-dev** - SDL2 core library
- **libsdl2-image-dev** - SDL2 image loading library

The project uses C++17 standard.

## Architecture

The codebase is structured into three main components:

### 1. Command-Line Interface (`xbrzscale.cpp`)
- Entry point with argument parsing
- Validates scale factor (2-6 inclusive)
- Initializes SDL2, loads input image, saves output PNG
- Thin wrapper around libxbrzscale

### 2. Scaling Library (`libxbrzscale.cpp/h`)
- Provides `libxbrzscale::scale()` - main scaling function
- Converts between SDL_Surface and uint32_t arrays
- Handles pixel format conversion (SDL surface ↔ ARGB uint32 arrays)
- Utility functions for SDL surface manipulation:
  - `SDL_GetPixel()` / `SDL_PutPixel()` - pixel access for various bit depths
  - `createARGBSurface()` - creates 32-bit ARGB surfaces
  - `surfaceToUint32()` / `uint32toSurface()` - format conversion

### 3. xBRZ Algorithm (`xbrz/` directory)
- Third-party library from https://sourceforge.net/projects/xbrz/
- Currently at version 1.8
- Core scaling algorithm implementation
- Accepts ARGB format uint32 arrays
- Supports scale factors 2-6, ColorFormat enum, and optional ScalerCfg parameters

## Data Flow

```
Input Image (any SDL_image format)
    ↓
SDL_Surface (loaded by IMG_Load)
    ↓
uint32_t array (ARGB format via surfaceToUint32)
    ↓
xbrz::scale() - applies pixel art scaling algorithm
    ↓
uint32_t array (scaled)
    ↓
SDL_Surface (via uint32toSurface)
    ↓
PNG file (saved via IMG_SavePNG)
```

## Build Artifacts

The build produces:
- **xbrzscale** (or xbrzscale.exe on Windows) - final executable
- **libxbrzscale.a** - static library containing libxbrzscale and xbrz object files
- Object files: `xbrzscale.o`, `libxbrzscale.o`, `xbrz/xbrz.o`

## Testing

The primary testing workflow is manual:
1. Build the tool
2. Run with test images: `./xbrzscale <scale_factor> <input_image> <output_image>`
3. Verify output visually

Note: Scaling has been primarily tested with 32-bit RGBA PNGs. Support for 8-bit indexed images is untested.

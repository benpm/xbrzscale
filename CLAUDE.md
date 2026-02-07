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

The codebase consists of multiple implementations and components:

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

### 4. C API Wrapper (`xbrz_c_api.cpp`)
- Simple C-compatible interface for external bindings
- Exports `xbrz_scale()` and `xbrz_version()` functions
- Used by Python ctypes wrapper
- Built as shared library (`xbrz_shared.dll/.so/.dylib`)
- No SDL dependencies (pure xBRZ algorithm)

### 5. Python Implementation (`python/` directory)
- Full-featured Python wrapper using ctypes
- Package manager: uv with `pyproject.toml`
- Dependencies: numpy (arrays) + Pillow (image I/O)
- Two interfaces:
  - **CLI tool**: `xbrzscale-py <scale> <input> <output>`
  - **Python API**: `from xbrzscale import scale_image`
- Automatic library discovery in build directories
- Comprehensive error handling and validation

**Python Architecture:**
- `library.py`: Automatic library discovery with ctypes
- `wrapper.py`: Efficient numpy ↔ C array conversion (RGBA ↔ ARGB uint32)
- `__main__.py`: CLI with comprehensive error handling
- Supports all image formats Pillow can read, outputs PNG

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

The CMake build produces:
- **xbrzscale** (or xbrzscale.exe on Windows) - C++ CLI executable
- **libxbrzscale.a** - static library with SDL2 integration
- **xbrz.a** - static xBRZ algorithm library
- **xbrz_shared** (dll/so/dylib) - shared library for Python bindings
- Required DLLs on Windows: SDL2.dll, SDL2_image.dll (auto-copied to output)

The Python package (`python/`) requires the C++ shared library to be built first.

## Testing

### C++ Testing
Manual testing workflow:
1. Build the tool
2. Run with test images: `./xbrzscale <scale_factor> <input_image> <output_image>`
3. Verify output visually

### Python Testing
```bash
cd python
uv pip install -e .
xbrzscale-py 4 test_input.png test_output.png
```

Or use the Python API directly in scripts.

### Automated Testing
GitHub Actions workflows automatically:
- Build executables on Windows, Linux, and macOS
- Run basic smoke tests
- Generate example gallery with upscaled images
- Create releases with pre-built binaries

Note: Scaling has been primarily tested with 32-bit RGBA PNGs. Support for 8-bit indexed images is untested.

## GitHub Actions Workflows

### Build Workflow (`.github/workflows/build.yml`)
- Triggers: Push, pull requests, releases
- Builds on: Windows, Linux, macOS
- Uploads artifacts for all platforms
- Automatically creates release archives on tags
- Uploads binaries to GitHub releases

### Generate Examples Workflow (`.github/workflows/generate-examples.yml`)
- Triggers: Changes to example images or workflow
- Builds xbrzscale on Windows
- Upscales all images in `examples/` (2x, 3x, 4x)
- Generates EXAMPLES.md with before/after comparisons
- Auto-commits results back to repository

## Python Package Installation

After building the C++ shared library:

```bash
cd python
uv venv                  # Create virtual environment
uv pip install -e .      # Install in development mode
```

The Python package will automatically find the shared library in `../build/Release/` or `../build/`.

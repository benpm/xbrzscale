# Python xBRZ Wrapper Implementation Design

Date: 2026-02-05

## Overview

This document describes the design for a Python implementation of xbrzscale that wraps the existing C++ xBRZ library using ctypes.

## Architecture

The Python implementation consists of three layers:

1. **C++ Shared Library Layer** - The existing xBRZ C++ code compiled as a shared library (.so/.dll) via CMake with exported C-compatible functions
2. **Python Binding Layer** - A ctypes wrapper module that loads the shared library and provides Python-friendly interfaces
3. **CLI Application Layer** - A command-line tool that mimics the C++ version's interface

## Technology Choices

- **Bindings**: ctypes (pure Python, no compilation needed)
- **Image I/O**: Pillow (industry standard)
- **Arrays**: numpy (efficient array handling)
- **Package Management**: uv
- **Build**: Assumes pre-built shared library from CMake

## Components

### 1. Shared Library Modifications
- Modify CMake to produce shared library with C-compatible exports
- Add C API wrapper functions like `xbrz_scale_image(uint32_t* src, uint32_t* dst, int width, int height, int scale)`

### 2. Python Binding Module (`xbrzscale/wrapper.py`)
- Uses ctypes to load the shared library
- Provides `scale_image(input_array: np.ndarray, scale: int) -> np.ndarray`
- Handles numpy array → C array conversion
- Manages memory allocation/deallocation
- Searches for library in multiple locations

### 3. CLI Tool (`xbrzscale/__main__.py`)
- Argparse-based CLI: `xbrzscale <scale> <input> <output>`
- Uses Pillow to load input images
- Converts PIL Image → numpy → xBRZ → numpy → PIL Image
- Saves as PNG only

## Data Flow

1. Load image with Pillow: `PIL.Image.open(input_file)`
2. Convert to RGBA if needed: `image.convert('RGBA')`
3. Convert to numpy uint32 array in ARGB format
4. Reshape to contiguous 1D array for C interop
5. Call ctypes wrapper: `scaled = xbrz_scale(input_array, width, height, scale)`
6. Reshape result back to (new_height, new_width, 4)
7. Convert to PIL Image: `Image.fromarray(scaled, 'RGBA')`
8. Save as PNG: `image.save(output_file, 'PNG')`

## Library Loading

Search for shared library in order:
1. Environment variable `XBRZ_LIBRARY_PATH` if set
2. `../build/Release/libxbrzscale.{so,dll,dylib}`
3. `../build/libxbrzscale.{so,dll,dylib}`
4. System library paths

Raise clear error if library not found with build instructions.

## Error Handling

- **Library not found**: `ImportError` with build instructions
- **Invalid scale factor**: `ValueError` with valid range
- **Image loading failure**: Re-raise Pillow exceptions with context
- **Memory allocation failure**: Raise `MemoryError`
- **File I/O errors**: Propagate with added context

## Project Structure

```
python/
├── pyproject.toml          # uv configuration, dependencies
├── README.md               # Python-specific docs
├── xbrzscale/
│   ├── __init__.py        # Package exports
│   ├── __main__.py        # CLI entry point
│   ├── wrapper.py         # ctypes bindings
│   └── library.py         # Library loading logic
└── tests/
    ├── test_wrapper.py    # Unit tests
    └── test_cli.py        # CLI integration tests
```

## Implementation Phases

1. **Phase 1**: Modify CMakeLists.txt for shared library
2. **Phase 2**: Implement Python bindings
3. **Phase 3**: Implement CLI application
4. **Phase 4**: Testing & documentation

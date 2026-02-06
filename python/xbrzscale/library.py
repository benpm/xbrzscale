"""
Library loading utilities for xBRZ shared library
"""

import ctypes
import os
import platform
from pathlib import Path
from typing import Optional


def find_library() -> Optional[Path]:
    """
    Search for the xBRZ shared library in common locations.

    Returns:
        Path to the library if found, None otherwise
    """
    # Determine library extension based on platform
    system = platform.system()
    if system == "Windows":
        lib_name = "xbrz_shared.dll"
    elif system == "Darwin":
        lib_name = "libxbrz_shared.dylib"
    else:
        lib_name = "libxbrz_shared.so"

    # Check environment variable first
    env_path = os.environ.get("XBRZ_LIBRARY_PATH")
    if env_path:
        lib_path = Path(env_path)
        if lib_path.is_file():
            return lib_path

    # Get the directory containing this Python file
    this_dir = Path(__file__).parent

    # Search paths relative to the Python package
    search_paths = [
        # Relative to python/ directory
        this_dir / "../../build/Release" / lib_name,
        this_dir / "../../build" / lib_name,
        # Absolute paths in case we're installed
        Path("/usr/local/lib") / lib_name,
        Path("/usr/lib") / lib_name,
    ]

    for path in search_paths:
        resolved = path.resolve()
        if resolved.is_file():
            return resolved

    return None


def load_library() -> ctypes.CDLL:
    """
    Load the xBRZ shared library.

    Returns:
        Loaded library handle

    Raises:
        ImportError: If library cannot be found or loaded
    """
    lib_path = find_library()

    if lib_path is None:
        raise ImportError(
            "xBRZ shared library not found. Please build it first:\n"
            "  cd build && cmake --build . --config Release --target xbrz_shared\n"
            "Or set XBRZ_LIBRARY_PATH environment variable to the library path."
        )

    try:
        lib = ctypes.CDLL(str(lib_path))
    except OSError as e:
        raise ImportError(f"Failed to load xBRZ library from {lib_path}: {e}")

    # Define function signatures
    lib.xbrz_scale.argtypes = [
        ctypes.POINTER(ctypes.c_uint32),  # src
        ctypes.POINTER(ctypes.c_uint32),  # dst
        ctypes.c_int,                      # width
        ctypes.c_int,                      # height
        ctypes.c_int,                      # scale
    ]
    lib.xbrz_scale.restype = ctypes.c_int

    lib.xbrz_version.argtypes = []
    lib.xbrz_version.restype = ctypes.c_char_p

    return lib


# Load library on module import
_library = load_library()


def get_library() -> ctypes.CDLL:
    """Get the loaded xBRZ library handle."""
    return _library

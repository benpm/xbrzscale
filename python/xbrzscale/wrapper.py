"""
Python wrapper for xBRZ scaling algorithm
"""

import ctypes
import numpy as np
from typing import Union

from .library import get_library


def scale_image(image: np.ndarray, scale: int) -> np.ndarray:
    """
    Scale an image using the xBRZ algorithm.

    Args:
        image: Input image as numpy array with shape (height, width, 4) in RGBA format
               or (height, width, 3) in RGB format. dtype should be uint8.
        scale: Scale factor, must be between 2 and 6 (inclusive)

    Returns:
        Scaled image as numpy array with shape (height*scale, width*scale, 4) in RGBA format

    Raises:
        ValueError: If scale factor is invalid or image format is incorrect
        RuntimeError: If scaling operation fails
    """
    # Validate scale factor
    if not isinstance(scale, int) or scale < 2 or scale > 6:
        raise ValueError(f"Scale factor must be an integer between 2 and 6, got {scale}")

    # Validate and prepare input image
    if not isinstance(image, np.ndarray):
        raise ValueError("Image must be a numpy array")

    if image.ndim != 3:
        raise ValueError(f"Image must be 3-dimensional (height, width, channels), got shape {image.shape}")

    height, width, channels = image.shape

    # Convert to RGBA if needed
    if channels == 3:
        # Add alpha channel
        rgba = np.zeros((height, width, 4), dtype=np.uint8)
        rgba[:, :, :3] = image
        rgba[:, :, 3] = 255
        image = rgba
    elif channels == 4:
        # Already RGBA, ensure it's uint8
        if image.dtype != np.uint8:
            image = image.astype(np.uint8)
    else:
        raise ValueError(f"Image must have 3 (RGB) or 4 (RGBA) channels, got {channels}")

    # Convert RGBA uint8 to ARGB uint32
    # Input format: RGBA bytes [R, G, B, A]
    # Output format: ARGB uint32 (A << 24 | R << 16 | G << 8 | B)
    r = image[:, :, 0].astype(np.uint32)
    g = image[:, :, 1].astype(np.uint32)
    b = image[:, :, 2].astype(np.uint32)
    a = image[:, :, 3].astype(np.uint32)

    argb_input = (a << 24) | (r << 16) | (g << 8) | b

    # Flatten to 1D array for C interop
    input_flat = argb_input.flatten()

    # Allocate output buffer
    output_height = height * scale
    output_width = width * scale
    output_flat = np.zeros(output_height * output_width, dtype=np.uint32)

    # Get library and call xbrz_scale
    lib = get_library()

    # Convert numpy arrays to ctypes pointers
    input_ptr = input_flat.ctypes.data_as(ctypes.POINTER(ctypes.c_uint32))
    output_ptr = output_flat.ctypes.data_as(ctypes.POINTER(ctypes.c_uint32))

    # Call the C function
    result = lib.xbrz_scale(input_ptr, output_ptr, width, height, scale)

    if result != 0:
        raise RuntimeError(f"xBRZ scaling failed with error code {result}")

    # Convert ARGB uint32 back to RGBA uint8
    # Extract components from uint32
    output_a = ((output_flat >> 24) & 0xFF).astype(np.uint8)
    output_r = ((output_flat >> 16) & 0xFF).astype(np.uint8)
    output_g = ((output_flat >> 8) & 0xFF).astype(np.uint8)
    output_b = (output_flat & 0xFF).astype(np.uint8)

    # Reshape and stack into RGBA
    output_rgba = np.zeros((output_height, output_width, 4), dtype=np.uint8)
    output_rgba[:, :, 0] = output_r.reshape(output_height, output_width)
    output_rgba[:, :, 1] = output_g.reshape(output_height, output_width)
    output_rgba[:, :, 2] = output_b.reshape(output_height, output_width)
    output_rgba[:, :, 3] = output_a.reshape(output_height, output_width)

    return output_rgba


def get_version() -> str:
    """
    Get the xBRZ library version.

    Returns:
        Version string
    """
    lib = get_library()
    version_bytes = lib.xbrz_version()
    return version_bytes.decode('utf-8')

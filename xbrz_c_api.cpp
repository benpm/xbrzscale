/*
 * C API wrapper for xBRZ library
 * Provides a simple C-compatible interface for Python ctypes bindings
 */

#include "xbrz/xbrz.h"
#include <cstdint>
#include <cstring>

// Export declarations for Windows DLL
#ifdef _WIN32
    #define XBRZ_API __declspec(dllexport)
#else
    #define XBRZ_API __attribute__((visibility("default")))
#endif

extern "C" {

/**
 * Scale an image using xBRZ algorithm
 *
 * @param src Source image data in ARGB format (uint32 per pixel)
 * @param dst Destination buffer (must be pre-allocated to width*height*scale*scale)
 * @param width Source image width
 * @param height Source image height
 * @param scale Scale factor (2-6)
 * @return 0 on success, -1 on error
 */
XBRZ_API int xbrz_scale(const uint32_t* src, uint32_t* dst, int width, int height, int scale) {
    if (!src || !dst) return -1;
    if (scale < 2 || scale > 6) return -1;
    if (width <= 0 || height <= 0) return -1;

    xbrz::scale(scale, src, dst, width, height, xbrz::ColorFormat::ARGB);
    return 0;
}

/**
 * Get the version of xBRZ library
 * @return Version string
 */
XBRZ_API const char* xbrz_version() {
    return "1.8";
}

}

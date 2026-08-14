# REMOVED.md — Record of code stripped from this repository

This repository was reduced to its Aseprite work (`aseprite-plugin/`, its packaging
workflow, its test scripts, and its example sprite). Everything else — the C++ CLI,
the xBRZ algorithm vendored source, the C API, the Python package, the build system,
the example gallery, and the CI that produced it — was deleted.

This file documents what was deleted in enough detail to recreate it.

## Recovery

**The fastest recreation path is git, not this file.** Nothing here is lost history:

- **`138f912`** ("Add CMake presets for LLVM and MSVC with Ninja Multi-Config"), the last
  commit on `aseprite` before the strip, is the only ref holding *everything* — recover
  from here.
- The **`master`** branch holds the original project but **not** the aseprite-era
  additions: `CMakePresets.json` and the preset documentation were added on the
  `aseprite` branch only, and `master` still pins SDL2 at `release-2.30.10`.
- Upstream of the original project: `git@github.com:atheros/xbrzscale.git` (remote `upstream`).

```bash
git checkout 138f912 -- CMakeLists.txt CMakePresets.json Makefile Makefile-win \
    xbrz/ libxbrzscale.cpp libxbrzscale.h xbrzscale.cpp xbrz_c_api.cpp python/
```

Use this document when git is unavailable, or as a design summary.

## ⚠️ Consequence for the plugin

`aseprite-plugin/xbrz-filter.lua` **shells out to an `xbrzscale` executable at runtime.**
That executable's source was removed here, so the plugin has no in-repo way to build
its own backend. To use the plugin you must supply the binary from one of:

- A checkout of commit `138f912`, built with CMake (see §5). **This is the reliable path.**
- Reconstruction from §1–§5 below.
- ~~Prebuilt archives from GitHub releases~~ — the removed `build.yml` was *designed* to
  publish `xbrzscale-windows.zip` / `-linux.tar.gz` / `-macos.tar.gz` on release, and the
  old README advertised them, but **`benpm/xbrzscale` has no published releases**
  (verified with `gh release list` at strip time). No prebuilt binary exists to download.

The plugin searches for the binary in `build/Release/`, `build/`, `../build/Release/`,
`../build/`, and the current directory / PATH — see the `xbrzPaths` table in the Lua source.

---

# 1. C++ command-line tool — `xbrzscale.cpp`

GPL-3.0-or-later. Copyright (c) 2014 Przemysław Grzywacz <nexather@gmail.com>.

A thin `main()` wrapper. Behavior, exactly as the Lua plugin depends on it:

- **Usage:** `xbrzscale <scale_factor> <input_image> <output_image>`
- With `argc != 4`, prints to **stderr** and returns 1:
  ```
  usage: xbrzscale scale_factor input_image output_image
  scale_factor can be between 2 and 6
  ```
  > The plugin's executable-detection probe runs the binary with no arguments and
  > greps the combined output for the strings `usage` or `scale_factor`. Any
  > reimplementation must keep those two words in the no-args message or the plugin
  > will report "xbrzscale executable not found".
- Parses scale with `atoi(argv[1])`; rejects `< 2 || > 6` with
  `"scale_factor must be between 2 and 6 (inclusive), got %i\n"`, returns 1.
- `SDL_Init(SDL_INIT_VIDEO)`; on failure prints `"Failed to initialize SDL: %s\n"`, returns 1.
- `IMG_Load(in_file)`; on failure prints `"Failed to load source image '%s': %s\n"`, returns 1.
- `libxbrzscale::setEnableOutput(true)`, then `libxbrzscale::scale(src_img, scale)`;
  returns 1 if null.
- `IMG_SavePNG(dst_img, out_file)`, `SDL_FreeSurface(dst_img)`, `SDL_Quit()`, return 0.

Includes: `SDL2/SDL.h`, `SDL_error.h`, `SDL_image.h`, `SDL_main.h`, `SDL_surface.h`,
`<cstdio>`, `<cstdlib>`, `"libxbrzscale.h"`. The file also carried a large commented-out
`displayImage()` SDL1.x preview helper (dead code, SDL_SetVideoMode/SDL_Flip era).

# 2. SDL integration library — `libxbrzscale.h` / `libxbrzscale.cpp`

GPL-3.0-or-later, same copyright header. Full header, verbatim:

```cpp
#include <SDL2/SDL_stdinc.h>

struct SDL_Surface;

class libxbrzscale
{
 public:
  static inline Uint32 SDL_GetPixel(SDL_Surface *surface, int x, int y);
  static inline void SDL_PutPixel(SDL_Surface *surface, int x, int y, Uint32 pixel);
  static SDL_Surface* createARGBSurface(int w, int h);
  static SDL_Surface* scale(SDL_Surface* src_img,int scale);
  static void setEnableOutput(bool b){bEnableOutput=true;};
  static uint32_t* surfaceToUint32(SDL_Surface* img);
  static void uint32toSurface(uint32_t* dest, SDL_Surface* dst_img);
 private:
  static bool bEnableOutput;
};
```

> Note the upstream bug preserved as-is: `setEnableOutput(bool b)` ignores `b` and
> always assigns `true`.

Implementation notes:

- `bool libxbrzscale::bEnableOutput = false;` at file scope.
- **`SDL_GetPixel`** — classic SDL pixel fetch. `bpp = surface->format->BytesPerPixel`;
  `p = (Uint8*)surface->pixels + y*surface->pitch + x*bpp`; switch on bpp:
  1 → `*p`; 2 → `*(Uint16*)p`; 3 → endian-dependent
  (`SDL_BIG_ENDIAN`: `p[0]<<16 | p[1]<<8 | p[2]`, else `p[0] | p[1]<<8 | p[2]<<16`);
  4 → `*(Uint32*)p`; default → 0.
- **`SDL_PutPixel`** — the exact inverse, same bpp switch and endian handling.
- **`createARGBSurface(w, h)`** — one line:
  ```cpp
  return SDL_CreateRGBSurface(0, w, h, 32, 0xff0000U, 0xff00U, 0xffU, 0xff000000U);
  ```
  (R=0x00FF0000, G=0x0000FF00, B=0x000000FF, A=0xFF000000.)
- **`surfaceToUint32(img)`** — allocates `new uint32_t[img->w * img->h]`, iterates
  row-major, `SDL_GetPixel` + `SDL_GetRGBA(c, img->format, &r,&g,&b,&a)`, packs
  `(a<<24) | (r<<16) | (g<<8) | b`. Caller owns the buffer (`delete[]`).
- **`uint32toSurface(ui32src, dst_img)`** — unpacks a/r/g/b from the same layout,
  `SDL_MapRGBA(dst_img->format, r,g,b,a)`, `SDL_PutPixel`.
- **`scale(src_img, scale)`** — the pipeline:
  1. `dst_width = src->w * scale`, `dst_height = src->h * scale`.
  2. `in_data = surfaceToUint32(src_img)`, then **`SDL_FreeSurface(src_img)`**
     (the function consumes and frees its input surface — a caller must not reuse it).
  3. Prints `"Scaling image...\n"` if `bEnableOutput`.
  4. `dest = new uint32_t[dst_width*dst_height]`;
     `xbrz::scale(scale, in_data, dest, src_width, src_height, xbrz::ColorFormat::ARGB);`
     `delete[] in_data;`
  5. Prints `"Saving image...\n"` if `bEnableOutput`.
  6. `dst_img = createARGBSurface(...)`; on null → `delete[] dest`, print
     `"Failed to create SDL surface: %s\n"`, return NULL.
  7. `uint32toSurface(dest, dst_img)`; returns `dst_img`.
     (`dest` is leaked here in the original — a known upstream leak.)

**Data flow of the whole tool:**

```
Input image (any SDL_image format)
    ↓ IMG_Load
SDL_Surface
    ↓ surfaceToUint32
uint32_t[] (ARGB)
    ↓ xbrz::scale
uint32_t[] (scaled, ARGB)
    ↓ createARGBSurface + uint32toSurface
SDL_Surface (32-bit ARGB)
    ↓ IMG_SavePNG
PNG file
```

# 3. Vendored xBRZ algorithm — `xbrz/`

Third-party, **not** written in this repo. Do not retype it — fetch it.

- Source: <https://sourceforge.net/projects/xbrz/files/xBRZ/>
- Version vendored: **1.8**
- Files: `xbrz.cpp`, `xbrz.h`, `xbrz_config.h`, `xbrz_tools.h`, `config.h`,
  `Changelog.txt`, `License.txt` (GPL-3.0).
- API used by this project:
  ```cpp
  namespace xbrz {
    enum class ColorFormat { RGB, ARGB, ARGB_UNBUFFERED };
    void scale(size_t factor, const uint32_t* src, uint32_t* trg,
               int srcWidth, int srcHeight, ColorFormat colFmt,
               const ScalerCfg& cfg = ScalerCfg(),
               int yFirst = 0, int yLast = std::numeric_limits<int>::max());
  }
  ```
  Factors 2–6. Built with `NDEBUG` defined (see CMake below).

`License.txt` at the repo root is the GPL-3.0 text that covers this and the rest of
the project; it was **kept**, because the plugin is distributed under the same license.

# 4. C API for FFI — `xbrz_c_api.cpp`

Small enough to reproduce verbatim. No SDL dependency; compiled into `xbrz_shared`.

```cpp
/*
 * C API wrapper for xBRZ library
 * Provides a simple C-compatible interface for Python ctypes bindings
 */

#include "xbrz/xbrz.h"
#include <cstdint>
#include <cstring>

#ifdef _WIN32
    #define XBRZ_API __declspec(dllexport)
#else
    #define XBRZ_API __attribute__((visibility("default")))
#endif

extern "C" {

XBRZ_API int xbrz_scale(const uint32_t* src, uint32_t* dst, int width, int height, int scale) {
    if (!src || !dst) return -1;
    if (scale < 2 || scale > 6) return -1;
    if (width <= 0 || height <= 0) return -1;

    xbrz::scale(scale, src, dst, width, height, xbrz::ColorFormat::ARGB);
    return 0;
}

XBRZ_API const char* xbrz_version() {
    return "1.8";
}

}
```

`dst` must be pre-allocated to `width * height * scale * scale` uint32s.

# 5. Build system

## 5.1 `CMakeLists.txt`

`cmake_minimum_required(VERSION 3.14)`, `project(xbrzscale VERSION 1.0 LANGUAGES C CXX)`,
C++17 required.

**Dependencies via FetchContent** (pins as of the strip):

| Dep | Repo | Tag |
|---|---|---|
| SDL2 | `https://github.com/libsdl-org/SDL.git` | `release-2.32.10` (bumped from `release-2.30.10` in commit `07469d6`) |
| SDL2_image | `https://github.com/libsdl-org/SDL_image.git` | `release-2.8.4` |

Both `GIT_SHALLOW TRUE`, then `FetchContent_MakeAvailable(SDL2 SDL2_image)`.

**SDL2_image include workaround** — the project's sources `#include <SDL2/SDL_image.h>`
but SDL2_image does not install into an `SDL2/` subdirectory, so the build copies it:

```cmake
FetchContent_GetProperties(SDL2_image SOURCE_DIR SDL2_IMAGE_SOURCE_DIR)
file(MAKE_DIRECTORY ${SDL2_IMAGE_SOURCE_DIR}/include/SDL2)
file(COPY ${SDL2_IMAGE_SOURCE_DIR}/include/SDL_image.h
     DESTINATION ${SDL2_IMAGE_SOURCE_DIR}/include/SDL2)
```

**Targets:**

- `add_library(xbrz STATIC xbrz/xbrz.cpp xbrz/xbrz.h xbrz/xbrz_config.h xbrz/xbrz_tools.h xbrz/config.h)`
  with `target_compile_definitions(xbrz PRIVATE NDEBUG)` and
  `target_include_directories(xbrz PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})`.
- Include dirs are pulled off the SDL targets and their **parent** used (so `SDL2/…`
  resolves):
  ```cmake
  get_target_property(SDL2_INCLUDE_DIR SDL2::SDL2 INTERFACE_INCLUDE_DIRECTORIES)
  get_target_property(SDL2_IMAGE_INCLUDE_DIR SDL2_image::SDL2_image INTERFACE_INCLUDE_DIRECTORIES)
  # then used as ${SDL2_INCLUDE_DIR}/.. and ${SDL2_IMAGE_INCLUDE_DIR}/..
  ```
- `add_library(libxbrzscale STATIC libxbrzscale.cpp libxbrzscale.h)`, links
  `PUBLIC xbrz SDL2::SDL2`.
- `add_executable(xbrzscale xbrzscale.cpp)`, links
  `PRIVATE libxbrzscale SDL2::SDL2main SDL2::SDL2 SDL2_image::SDL2_image`.
- `if(WIN32)` POST_BUILD custom command copying `$<TARGET_FILE:SDL2::SDL2>` and
  `$<TARGET_FILE:SDL2_image::SDL2_image>` into `$<TARGET_FILE_DIR:xbrzscale>`
  (`copy_if_different`), comment `"Copying SDL2 DLLs to output directory"`.
- `add_library(xbrz_shared SHARED xbrz_c_api.cpp)`, links `PRIVATE xbrz`,
  properties `OUTPUT_NAME "xbrz_shared"`, `VERSION 1.0`, `SOVERSION 1`.
- `install(TARGETS xbrzscale DESTINATION bin)` and `install(TARGETS xbrz_shared DESTINATION lib)`.

## 5.2 `CMakePresets.json`

Schema `"version": 9`. A hidden `.common` configure preset sets generator
**Ninja Multi-Config**, cache vars `CMAKE_POLICY_VERSION_MINIMUM=3.5` and
`CMAKE_EXPORT_COMPILE_COMMANDS=true`, env `CLICOLOR_FORCE=1`.

Two configure presets inheriting it:

- **`windows-clang`** → `binaryDir: ./build/clang`,
  `CMAKE_CXX_COMPILER=C:/Program Files/LLVM/bin/clang++.exe`,
  `CMAKE_C_COMPILER=C:/Program Files/LLVM/bin/clang.exe`,
  and both `CMAKE_C_FLAGS` / `CMAKE_CXX_FLAGS` set to
  `-fdiagnostics-color=always -D__PRFCHWINTRIN_H -fno-builtin`.

  **Why those two odd flags** (worth keeping if the C++ side is ever restored):
  - `-D__PRFCHWINTRIN_H` suppresses a `_m_prefetch` redefinition between clang's
    `prfchwintrin.h` and SDL2's `SDL_endian.h`.
  - `-fno-builtin` stops clang from recognizing SDL's hand-rolled string loops in
    `SDL_stdinc.c` and lowering them to libc `strlen`/`wcslen` calls that SDL does
    not link, which otherwise fails at link time.

- **`windows-msvc`** → `binaryDir: ./build/msvc`, `CMAKE_CXX_COMPILER=cl`,
  `CMAKE_C_COMPILER=cl`. Requires a Developer PowerShell / vcvars64 environment.

Four build presets: `windows-clang-debug`, `windows-clang-release`,
`windows-msvc-debug`, `windows-msvc-release` — each pairing configuration
`Debug`/`Release` with its configure preset.

Usage was:

```bash
cmake --preset windows-clang
cmake --build --preset windows-clang-release
```

Outputs landed in `build/<toolchain>/<Config>/`.

## 5.3 `Makefile` (Linux/macOS, legacy)

Requires system-installed SDL2 + SDL2_image (`libsdl2-dev`, `libsdl2-image-dev`).

```make
all: xbrzscale

xbrz/xbrz.o: xbrz/xbrz.cpp xbrz/xbrz.h
	g++ -std=c++17 -c -o xbrz/xbrz.o xbrz/xbrz.cpp -DNDEBUG

libxbrzscale.o: libxbrzscale.cpp xbrz/xbrz.h
	g++ -std=c++17 -c -o libxbrzscale.o libxbrzscale.cpp `sdl2-config --cflags`

xbrzscale.o: xbrzscale.cpp libxbrzscale.h xbrz/xbrz.h
	g++ -std=c++17 -c -o xbrzscale.o xbrzscale.cpp `sdl2-config --cflags`

libxbrzscale.a: libxbrzscale.o xbrz/xbrz.o
	ar qc libxbrzscale.a libxbrzscale.o xbrz/xbrz.o

xbrzscale: xbrzscale.o libxbrzscale.a
	g++ -o xbrzscale xbrzscale.o libxbrzscale.a -lSDL2_image `sdl2-config --libs`

clean:
	rm -vf xbrzscale.o xbrz/xbrz.o libxbrzscale.o libxbrzscale.a xbrzscale
```

## 5.4 `Makefile-win` (MinGW, legacy)

Same target graph; differences are the link lines and `del`-based clean:

```make
xbrz/xbrz.o:        g++ -std=c++17 -c -o xbrz/xbrz.o xbrz/xbrz.cpp
libxbrzscale.o:     g++ -std=c++17 -c -o libxbrzscale.o libxbrzscale.cpp -lmingw32 -lSDL2main -lSDL2 -lSDL2_image
xbrzscale.o:        g++ -std=c++17 -c -o xbrzscale.o xbrzscale.cpp
libxbrzscale.a:     ar qc libxbrzscale.a libxbrzscale.o xbrz/xbrz.o
xbrzscale:          g++ -o xbrzscale xbrzscale.o libxbrzscale.a -lmingw32 -lSDL2_image -lSDL2main -lSDL2 -static-libgcc -static-libstdc++
clean:              del xbrzscale.o xbrz\xbrz.o libxbrzscale.o libxbrzscale.a
```

Invoked as `mingw32-make -f Makefile-win`.

# 6. Python package — `python/`

A ctypes binding over `xbrz_shared`, with numpy arrays and Pillow I/O. Requires the
shared library to be built first. Managed with `uv`.

```
python/
├── pyproject.toml
├── README.md
└── xbrzscale/
    ├── __init__.py
    ├── __main__.py     # CLI
    ├── wrapper.py      # numpy ↔ C conversion
    └── library.py      # library discovery + ctypes signatures
```

## 6.1 `pyproject.toml`

```toml
[project]
name = "xbrzscale"
version = "1.0.0"
description = "Python wrapper for xBRZ pixel art scaling algorithm"
readme = "README.md"
requires-python = ">=3.8"
license = {text = "GPL-3.0-or-later"}
dependencies = ["numpy>=1.20", "Pillow>=9.0"]

[project.scripts]
xbrzscale-py = "xbrzscale.__main__:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[dependency-groups]
dev = ["pytest>=7.0"]
```

## 6.2 `xbrzscale/__init__.py`

```python
from .wrapper import scale_image, get_version
__version__ = "1.0.0"
__all__ = ["scale_image", "get_version"]
```

## 6.3 `xbrzscale/library.py`

- `find_library() -> Optional[Path]`. Platform library name:
  Windows → `xbrz_shared.dll`; Darwin → `libxbrz_shared.dylib`; else `libxbrz_shared.so`.
  Search order:
  1. `$XBRZ_LIBRARY_PATH` (used directly if it is a file),
  2. `<pkg>/../../build/Release/<lib>`,
  3. `<pkg>/../../build/<lib>`,
  4. `/usr/local/lib/<lib>`,
  5. `/usr/lib/<lib>`.
  Each candidate `.resolve()`d and `.is_file()`-checked.
- `load_library() -> ctypes.CDLL`. Raises `ImportError` when not found, with the message
  telling the user to run
  `cd build && cmake --build . --config Release --target xbrz_shared`
  or set `XBRZ_LIBRARY_PATH`. Wraps `OSError` from `CDLL` into `ImportError`.
  Then declares signatures:
  ```python
  lib.xbrz_scale.argtypes = [POINTER(c_uint32), POINTER(c_uint32), c_int, c_int, c_int]
  lib.xbrz_scale.restype  = c_int
  lib.xbrz_version.argtypes = []
  lib.xbrz_version.restype  = c_char_p
  ```
- Module-level `_library = load_library()` — **loads eagerly at import time** — plus
  `get_library()` returning it.

## 6.4 `xbrzscale/wrapper.py`

`scale_image(image: np.ndarray, scale: int) -> np.ndarray`

- Validates `isinstance(scale, int) and 2 <= scale <= 6`, else `ValueError`.
- Validates ndarray, `ndim == 3`. Unpacks `height, width, channels`.
- `channels == 3` → allocate `(h, w, 4)` uint8, copy RGB, set alpha 255.
  `channels == 4` → cast to uint8 if needed. Anything else → `ValueError`.
- **RGBA uint8 → ARGB uint32**: `(a << 24) | (r << 16) | (g << 8) | b`, each channel
  cast to uint32 first; then `.flatten()`.
- Allocates `np.zeros(h*scale * w*scale, dtype=np.uint32)` for output.
- `input_flat.ctypes.data_as(POINTER(c_uint32))` for both buffers, calls
  `lib.xbrz_scale(input_ptr, output_ptr, width, height, scale)`; nonzero →
  `RuntimeError(f"xBRZ scaling failed with error code {result}")`.
- **ARGB uint32 → RGBA uint8**: shift/mask each channel, reshape to
  `(output_height, output_width)`, assemble into an `(oh, ow, 4)` uint8 array.

`get_version() -> str` — `lib.xbrz_version().decode('utf-8')` (returns `"1.8"`).

## 6.5 `xbrzscale/__main__.py`

Argparse CLI registered as `xbrzscale-py`:

- Positional `scale` (int), `input` (str), `output` (str); `--version` action prints
  `f"xbrzscale {get_version()}"`. `RawDescriptionHelpFormatter` with an epilog showing
  `xbrzscale-py 4 input.png output.png` and `xbrzscale-py 2 sprite.bmp sprite_2x.png`.
- Re-validates scale 2–6 → stderr + return 1.
- Checks input path exists → `"Error: Input file not found: …"`, return 1.
- `Image.open`, `.convert("RGBA")` if `mode != "RGBA"`, `np.array(img)`; prints
  `"Image size: {w}x{h}"`.
- Calls `scale_image`, prints scaled size.
- `Image.fromarray(scaled, "RGBA").save(args.output, "PNG")`, prints `"Done!"`.
- Every stage wrapped in try/except printing `Error: …` to stderr and returning 1.
- `if __name__ == "__main__": sys.exit(main())`.

## 6.6 `python/README.md`

Install instructions (build `xbrz_shared` via CMake, then `uv pip install -e .` from
`python/`), CLI usage, and a Python-API snippet loading with Pillow → numpy →
`scale_image(img_array, scale=4)` → `Image.fromarray(...).save(...)`.

# 7. Design docs — `docs/plans/2026-02-05-python-implementation-design.md`

The design doc that preceded §6, dated 2026-02-05. It specified the three layers
(C++ shared library / ctypes binding / CLI), the technology choices (ctypes, Pillow,
numpy, uv, prebuilt shared lib), the data flow, the library search order, the error
handling table (`ImportError` / `ValueError` / re-raised Pillow errors / `MemoryError`),
the `python/` directory layout (including a `tests/` dir with `test_wrapper.py` and
`test_cli.py` that were never actually written), and four implementation phases:
CMake shared lib → bindings → CLI → tests & docs.

Notably it proposed the C entry point as
`xbrz_scale_image(uint32_t* src, uint32_t* dst, int width, int height, int scale)`;
the shipped name was `xbrz_scale`.

# 8. Example gallery — `examples/*.png`, `examples/upscaled/`, `EXAMPLES.md`

**Kept:** `examples/aseprite_test.ase` (the Aseprite test sprite).

**Removed:**

- `examples/threeformsPJ2.png`, `examples/walk - sword.png` — the two source sprites.
- `examples/upscaled/` — six generated PNGs:
  `threeformsPJ2_{2x,3x,4x}.png` and `walk - sword_{2x,3x,4x}.png`.
- `EXAMPLES.md` — fully machine-generated (see §9.3); never hand-edited. It contained a
  header, then per source image a section with original pixel dimensions and
  `<img>` tags for the original plus 2x/3x/4x upscales, then an "About xBRZ" blurb
  linking <https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms#xBR_family>,
  a generation timestamp, and an Actions link.

Regenerating requires the source images (recoverable from git) plus the workflow.

> Side effect: `test-xbrz.lua` Test 5 looks for `examples/threeformsPJ2.png` to run a
> real 2x scale through the binary. With that file gone the test degrades gracefully —
> it prints `(Skipping - no test image found)` and the script still passes. Restore the
> PNG from git to re-enable that check.

# 9. GitHub Actions

**Kept:** `.github/workflows/package-aseprite-plugin.yml`.

**Removed:** `build.yml`, `generate-examples.yml`, and `.github/workflows/README.md`.

## 9.1 `build.yml`

`name: Build`. Triggers: push to `master`/`main`, PRs to those branches, and
`release: [published]`. Three independent jobs — `build-windows` (`windows-latest`),
`build-linux` (`ubuntu-latest`), `build-macos` (`macos-latest`). All use
`actions/checkout@v5` and `actions/upload-artifact@v4`.

Per-job shape:

1. Checkout.
2. (Linux) `apt-get install -y cmake ninja-build`; (macOS) `brew install cmake ninja`.
3. `mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release` — plus `-G Ninja`
   on Linux/macOS.
4. Build: Windows `cmake --build . --config Release`; others `cmake --build .`.
5. Smoke test: run the binary with no args, `continue-on-error: true`.
6. Package into a `xbrzscale-<os>/` dir:
   - Windows: `xbrzscale.exe`, `SDL2.dll`, `SDL2_image.dll`, `xbrz_shared.dll`, `README.md`, `License.txt`
   - Linux: `xbrzscale`, `libxbrz_shared.so`, `README.md`, `License.txt`
   - macOS: `xbrzscale`, `libxbrz_shared.dylib`, `README.md`, `License.txt`
7. Upload artifact named `xbrzscale-windows` / `-linux` / `-macos`.
8. `if: github.event_name == 'release'` — archive
   (`Compress-Archive` → `xbrzscale-windows.zip`; `tar -czf` → `xbrzscale-linux.tar.gz`,
   `xbrzscale-macos.tar.gz`) then
   `gh release upload ${{ github.event.release.tag_name }} <archive>` with
   `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}`.

## 9.2 `.github/workflows/README.md`

Documentation for the above: the build matrix table, artifact names, the release
procedure (`git tag v1.0.0 && git push origin v1.0.0`, then
`gh release create v1.0.0 --title … --notes …`), and a local-testing note about
running `act push -j build-windows` with nektos/act.

## 9.3 `generate-examples.yml`

`name: Generate Examples`. Triggers: push to `master`/`main` restricted to paths
`examples/*.png`, `examples/*.bmp`, `examples/*.jpg`, and the workflow file itself;
plus `workflow_dispatch`. `permissions: contents: write`. Single job on `windows-latest`.

Steps:

1. Checkout (`actions/checkout@v5`).
2. Configure + build only the `xbrzscale` target
   (`cmake --build . --config Release --target xbrzscale`).
3. Wipe and recreate `examples/upscaled`.
4. PowerShell step collecting `*.png`/`*.bmp`/`*.jpg` from `examples` (excluding the
   `upscaled` dir via `Where-Object { $_.DirectoryName -notmatch 'upscaled' }`), and
   for each running `build/Release/xbrzscale.exe $scale $img examples/upscaled/${basename}_${scale}x.png`
   for `$scale` in 2, 3, 4.
5. PowerShell step building `EXAMPLES.md` from a here-string template, using
   `System.Drawing` (`[System.Drawing.Image]::FromFile(...)`) to read each source
   image's width/height, emitting per-image sections with computed 2x/3x/4x sizes,
   then writing UTF-8 via `Out-File`.
6. `git add examples/upscaled/ EXAMPLES.md`, detect staged changes into
   `has_changes` via `$env:GITHUB_OUTPUT`.
7. If changed: configure user `github-actions[bot]` /
   `github-actions[bot]@users.noreply.github.com`, commit
   `"Update examples gallery with upscaled images [skip ci]"`, push.

# 10. Root docs

`README.md` and `CLAUDE.md` were **rewritten**, not deleted — they now describe the
plugin as the product. What they previously covered and no longer do:

- **`README.md`**: GPL header and upstream copyright (Przemysław Grzywacz); a Build
  Status badge (`https://github.com/benpm/xbrzscale/workflows/Build/badge.svg`);
  feature list; a link to the xBRZ SourceForge page; prebuilt-binary quick start from
  the releases page; the Python quick start; the dependency list (CMake 3.14+, C++17,
  SDL2/SDL2_image auto-fetched; Python 3.8+, numpy, Pillow); build-from-source sections
  for CMake and both legacy Makefiles; C++ CLI usage and the argument table; the Python
  API snippet; the caveat that scaling is primarily tested with 32-bit RGBA PNGs and
  8-bit indexed support is untested; the Aseprite plugin section; and a GitHub Actions
  summary.
- **`CLAUDE.md`**: build commands for CMake/presets/legacy Makefiles, the dependency
  list, the five-component architecture breakdown (CLI / scaling library / xBRZ /
  C API / Python), the data-flow diagram (reproduced in §2 above), the build-artifact
  list (`xbrzscale`, `libxbrzscale.a`, `xbrz.a`, `xbrz_shared.*`, auto-copied SDL DLLs),
  the C++/Python/automated testing notes, the workflow descriptions, and the Python
  install instructions (`uv venv`, `uv pip install -e .`).

# 11. Untracked local state

- `build/` — local CMake output (`build/clang/`). Ignored by git; regenerable.
- `external/zlib` — a **registered git submodule** whose `.git` file pointed at
  `gitdir: ../../.git/modules/external/zlib`. It appeared untracked in the worktree
  (no `.gitmodules` in the index) — leftover scaffolding, not referenced by any build
  file in the repo. Removed along with its `.git/modules/external/zlib` metadata.
  It was never wired into `CMakeLists.txt`; if zlib is needed again, add it fresh.

# 12. `.gitignore` entries that became inert

The root `.gitignore` previously carried, for the removed C++/Python code:

```
*.o
*.a
/xbrzscale
xbrzscale.exe
*.dll
build/
python/.venv/
python/__pycache__/
python/*.egg-info/
python/test_*.png
*.pyc
__pycache__/
```

plus `.idea/`. These were left in place — harmless, and correct again the moment any
of the above is restored.

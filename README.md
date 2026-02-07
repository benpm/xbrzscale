xBRZ upscaling commandline tool
===============================

![Build Status](https://github.com/benpm/xbrzscale/workflows/Build/badge.svg)

Copyright (c) 2020 Przemysław Grzywacz <nexather@gmail.com>

This file is part of xbrzscale.

xbrzscale is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.



Overview
--------

This tool allows you to scale your graphics with the xBRZ algorithm, see https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms#xBR_family

**Features:**
- Scale pixel art images 2x to 6x
- Preserves sharp edges and avoids blurriness
- Cross-platform (Windows, Linux, macOS)
- C++ CLI tool and Python wrapper
- Automated example gallery generation

**See examples:** [EXAMPLES.md](EXAMPLES.md)


External code
-------------

The following external code is included in this repository:

* https://sourceforge.net/projects/xbrz/files/xBRZ/ - xBRZ implementation

Quick Start
-----------

### Pre-built Binaries (Easiest)

Pre-built executables for Windows, Linux, and macOS are available on the [Releases page](https://github.com/benpm/xbrzscale/releases). Download, extract, and run!

### Python (Recommended for scripting)

```bash
# Install Python wrapper (requires pre-built C++ library)
cd python
uv pip install -e .

# Use from command line
xbrzscale-py 4 input.png output.png

# Or use in Python
from xbrzscale import scale_image
import numpy as np
scaled = scale_image(image_array, scale=4)
```

Dependencies
------------

**For C++ compilation:**
- CMake 3.14+
- C++17 compiler
- SDL2 and SDL2_image (automatically downloaded by CMake via FetchContent)

**For Python wrapper:**
- Python 3.8+
- numpy
- Pillow
- Pre-built xbrz_shared library (build C++ project first)


Building from Source
--------------------

### CMake (Recommended - All Platforms)

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

CMake automatically downloads and builds all dependencies. The executables will be in:
- Windows: `build/Release/xbrzscale.exe`
- Linux/macOS: `build/xbrzscale`

### Legacy Makefiles

**Linux/macOS:**
```bash
make
```

**Windows (MinGW):**
```bash
mingw32-make -f Makefile-win
```

Note: Legacy Makefiles require SDL2 libraries pre-installed on your system.

Usage
-----

### C++ Command Line

```bash
xbrzscale <scale_factor> <input_image> <output_image>
```

* `scale_factor` - Scale multiplier, must be between 2 and 6 (inclusive)
* `input_image` - Input file (any format SDL_image supports: PNG, BMP, JPG, etc.)
* `output_image` - Output file (PNG format only)

**Example:**
```bash
xbrzscale 4 sprite.png sprite_4x.png
```

### Python API

```python
from xbrzscale import scale_image
from PIL import Image
import numpy as np

# Load and scale
img = Image.open("input.png")
img_array = np.array(img)
scaled = scale_image(img_array, scale=4)

# Save result
Image.fromarray(scaled, "RGBA").save("output.png")
```

**Note:** Scaling works best with pixel art and has been primarily tested with 32-bit RGBA PNGs.

GitHub Actions
--------------

This repository includes automated workflows:

- **Build:** Automatically builds executables for Windows, Linux, and macOS on every push
- **Generate Examples:** Upscales example images and updates [EXAMPLES.md](EXAMPLES.md) with before/after comparisons

See `.github/workflows/` for workflow configurations.





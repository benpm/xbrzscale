# xbrzscale Python Wrapper

Python wrapper for the xBRZ pixel art scaling algorithm.

## Installation

First, build the C++ shared library:

```bash
cd ..
mkdir build && cd build
cmake ..
cmake --build . --config Release --target xbrz_shared
```

Then install the Python package:

```bash
cd ../python
uv pip install -e .
```

## Usage

```bash
xbrzscale-py <scale_factor> <input_image> <output_image>
```

Example:

```bash
xbrzscale-py 4 input.png output.png
```

Scale factor must be between 2 and 6 (inclusive).

## Python API

```python
from xbrzscale import scale_image
import numpy as np
from PIL import Image

# Load image
img = Image.open("input.png").convert("RGBA")
img_array = np.array(img)

# Scale 4x
scaled = scale_image(img_array, scale=4)

# Save result
Image.fromarray(scaled, "RGBA").save("output.png")
```

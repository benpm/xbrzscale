# xBRZ Filter Plugin for Aseprite

High-quality pixel art scaling plugin for Aseprite using the xBRZ algorithm.

## Features

- Scale pixel art images using the xBRZ algorithm
- Preserves sharp edges and avoids blurriness
- Multiple scale factors: 2x, 3x, 4x, 5x, and 6x
- Integrated into Aseprite's menu system

## Installation

### 1. Build xbrzscale

First, build the xbrzscale executable:

```bash
cd ..  # Go to the project root
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

### 2. Install the Plugin

There are two ways to install the plugin:

#### Option A: Manual Installation (Recommended)

1. Open Aseprite
2. Go to **Edit > Preferences > Extensions**
3. Click **Add Extension**
4. Navigate to the `aseprite-plugin` folder and select it
5. Restart Aseprite

#### Option B: Copy to Extensions Folder

Copy the entire `aseprite-plugin` folder to your Aseprite extensions directory:

**Windows:**
```
%APPDATA%\Aseprite\extensions\
```

**macOS:**
```
~/Library/Application Support/Aseprite/extensions/
```

**Linux:**
```
~/.config/aseprite/extensions/
```

### 3. Ensure xbrzscale is Accessible

The plugin needs to find the `xbrzscale` executable. You can either:

- **Add to PATH**: Add the directory containing xbrzscale to your system PATH
- **Copy to Aseprite folder**: Copy xbrzscale executable next to Aseprite executable
- **Local copy**: Place xbrzscale in the same directory as the plugin

The plugin automatically searches these locations:
- Current directory (`.`)
- Build directories (`./build/`, `./build/Release/`)
- Parent directories (`../`, `../build/`)
- System PATH

## Usage

1. Open a sprite in Aseprite
2. Select the layer/cel you want to scale
3. Go to **Sprite > Sprite Size** menu
4. Choose one of the xBRZ filters:
   - **xBRZ 2x** - Scale 2 times
   - **xBRZ 3x** - Scale 3 times
   - **xBRZ 4x** - Scale 4 times
   - **xBRZ 5x** - Scale 5 times
   - **xBRZ 6x** - Scale 6 times

The plugin will create a new sprite with the scaled image.

## How It Works

1. Exports the current cel/image to a temporary PNG file
2. Calls the xbrzscale executable with the chosen scale factor
3. Loads the scaled result into a new Aseprite sprite
4. Preserves color mode and palette from the original sprite

## Requirements

- Aseprite (tested with latest version)
- xbrzscale executable (built from this repository)

## Troubleshooting

**"xbrzscale executable not found"**
- Make sure you've built xbrzscale first
- Verify xbrzscale is in your PATH or in one of the searched locations
- Try copying xbrzscale.exe to the same folder as Aseprite.exe

**"xBRZ filter failed to execute"**
- Check that the input image format is supported
- Ensure you have write permissions for temporary files
- Verify the scale factor is valid (2-6)

**Plugin doesn't appear in menu**
- Restart Aseprite after installing the plugin
- Check that package.json and xbrz-filter.lua are in the same folder
- Verify the plugin is listed in Edit > Preferences > Extensions

## License

GPL-3.0 (same as xbrzscale)

## Credits

- xBRZ algorithm: https://sourceforge.net/projects/xbrz/
- xbrzscale: https://github.com/benpm/xbrzscale

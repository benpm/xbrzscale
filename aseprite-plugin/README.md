# xBRZ Filter Plugin for Aseprite

High-quality pixel art scaling plugin for Aseprite using the xBRZ algorithm.

## Features

- Scale pixel art images using the xBRZ algorithm
- Preserves sharp edges and avoids blurriness
- Multiple scale factors: 2x, 3x, 4x, 5x, and 6x
- Integrated into Aseprite's menu system

## Installation

### 1. Obtain the xbrzscale executable

This plugin does not scale images itself — it shells out to an `xbrzscale` binary.
**That binary is no longer built from this repository**; its source was removed when the
repo was narrowed to the Aseprite extension. See [../REMOVED.md](../REMOVED.md).

Build it from the last commit that contained it, `138f912`:

```bash
git worktree add ../xbrzscale-cli 138f912
cd ../xbrzscale-cli
cmake --preset windows-clang          # or: mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build --preset windows-clang-release
```

CMake fetches SDL2 and SDL2_image automatically. The executable lands in
`build/clang/Release/` (preset) or `build/Release/` (plain CMake), with the SDL2 DLLs
copied alongside it on Windows.

There are **no prebuilt binaries to download** — this repository has never published a
GitHub release. If you need the CLI without building it, REMOVED.md §1–§5 documents it
in enough detail to reimplement; anything you write must print a usage message
containing the word `usage` or `scale_factor` when run with no arguments, or the
detection below will not recognize it.

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

The plugin searches these paths in order, trying both the `.exe` and extension-less name
at each, and accepting the first that runs and prints a recognizable usage message:

- `build/Release/xbrzscale`
- `build/xbrzscale`
- `../build/Release/xbrzscale`
- `../build/xbrzscale`
- `xbrzscale` (current directory, then PATH)

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
- An `xbrzscale` executable — see step 1; **not** built by this repository anymore
- On Windows, `SDL2.dll` and `SDL2_image.dll` next to that executable

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

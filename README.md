# xBRZ Filter — Aseprite extension

An Aseprite extension that applies xBRZ pixel-art upscaling to the active cel, at
factors 2x through 6x. See
<https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms#xBR_family> for the
algorithm family.

This repository is now focused on the Aseprite extension. The C++ CLI tool, the C API,
the Python wrapper, and the build system that used to live here have been removed —
see **[REMOVED.md](REMOVED.md)** for a full record of what they were and how to
recreate them, and the `master` branch (or commit `138f912`) for the code itself.

## ⚠️ Runtime requirement

The extension does not upscale in-process. It writes the cel to a temporary PNG, shells
out to an **`xbrzscale` executable**, and reads the result back. That executable is no
longer built from this repository, so you must supply it:

```bash
git worktree add ../xbrzscale-cli 138f912
cd ../xbrzscale-cli && cmake --preset windows-clang && cmake --build --preset windows-clang-release
```

or reconstruct it from the notes in [REMOVED.md](REMOVED.md). There are **no prebuilt
binaries** — this repo has never published a release, despite the old README saying otherwise.

Put the binary somewhere the extension looks — `build/Release/`, `build/`,
`../build/Release/`, `../build/`, or on `PATH` / next to the Aseprite executable.
On Windows the SDL2 DLLs (`SDL2.dll`, `SDL2_image.dll`) must sit beside it.

## Install

**Option A — Aseprite UI:** Edit → Preferences → Extensions → Add Extension, and select
the `aseprite-plugin` folder (or a packaged `.aseprite-extension` zip). Restart Aseprite.

**Option B — copy into the extensions directory:**

| OS | Path |
|---|---|
| Windows | `%APPDATA%\Aseprite\extensions\` |
| macOS | `~/Library/Application Support/Aseprite/extensions/` |
| Linux | `~/.config/aseprite/extensions/` |

A packaged `xbrz-filter.aseprite-extension` zip is built on every push by
`.github/workflows/package-aseprite-plugin.yml` and attached to releases.

## Use

Open a sprite, select the cel to scale, then **Sprite → Sprite Size → xBRZ 2x / 3x / 4x
/ 5x / 6x**. The result opens as a **new sprite**, preserving the original's color mode
and first palette; the source sprite is untouched.

## Repository contents

```
aseprite-plugin/            the extension
├── package.json            Aseprite extension manifest
├── xbrz-filter.lua         plugin: commands, executable discovery, scale pipeline
├── README.md               install / usage / troubleshooting
└── .gitignore
test-xbrz.lua               harness: loads the plugin, checks init/exit, probes for the
                            binary, runs a real 2x scale if a sample image is present
test-path.lua               scratch: Windows path-quoting experiments for io.popen
examples/aseprite_test.ase  test sprite
.github/workflows/package-aseprite-plugin.yml
License.txt                 GPL-3.0
REMOVED.md                  what was stripped from this repo, and how to restore it
```

Run the test harness with:

```bash
aseprite --batch --script test-xbrz.lua
```

## License

GPL-3.0-or-later. The xBRZ algorithm is from
<https://sourceforge.net/projects/xbrz/>. The original `xbrzscale` CLI is
Copyright (c) 2014 Przemysław Grzywacz <nexather@gmail.com>.

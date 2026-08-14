# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository holds **xBRZ Filter**, an Aseprite extension that upscales the active
cel with the xBRZ pixel-art scaling algorithm at factors 2x–6x.

The repo was previously the `xbrzscale` C++ CLI project. Everything that was not part of
the Aseprite work — the CLI, `libxbrzscale`, the vendored `xbrz/` sources, the C API,
the Python ctypes package, CMake/Makefiles, the example gallery and its CI — has been
removed. **[REMOVED.md](REMOVED.md) is the record of all of it**, detailed enough to
recreate it; commit `138f912` and the `master` branch still contain the code.

## Critical: the external binary dependency

`aseprite-plugin/xbrz-filter.lua` does not implement xBRZ. It shells out to an
`xbrzscale` executable that **is no longer built from this repository**. Before
changing anything about the invocation path, know these two contracts:

1. **Discovery probe.** The plugin finds the binary by running each candidate with no
   arguments and checking that the combined output contains `usage` or `scale_factor`.
   Any replacement binary must print a usage message containing those words on stderr
   when called with the wrong argument count.
2. **CLI shape.** `xbrzscale <scale_factor> <input.png> <output.png>`, scale 2–6,
   output always PNG, exit 0 on success.

Candidate paths (in order): `build/Release/xbrzscale{.exe,}`, `build/xbrzscale{.exe,}`,
`../build/Release/xbrzscale{.exe,}`, `../build/xbrzscale{.exe,}`, `xbrzscale{.exe,}`.
Forward slashes are rewritten to backslashes before `io.popen` for Windows.

Obtain the binary by building commit `138f912` with CMake, or by reconstructing it from
REMOVED.md §1–§5. There are no prebuilt binaries — the repo has no published releases,
and `master` predates the aseprite-branch build additions.

## Layout

```
aseprite-plugin/
├── package.json      extension manifest — name `xbrz-filter`, contributes ./xbrz-filter.lua
├── xbrz-filter.lua   the plugin
├── README.md         end-user install/usage/troubleshooting
└── .gitignore        temp artifacts (xbrz_input_*.png, xbrz_output_*.png)
test-xbrz.lua         batch test harness
test-path.lua         scratch script for Windows path/quoting behavior under io.popen
examples/aseprite_test.ase
.github/workflows/package-aseprite-plugin.yml
License.txt           GPL-3.0
REMOVED.md
```

## How the plugin works

`init(plugin)` registers five commands — `XbrzFilter2x` … `XbrzFilter6x`, titled
`xBRZ 2x`…`xBRZ 6x`, all in group `sprite_size` (Sprite → Sprite Size menu). Each is
enabled only when `app.activeSprite` and `app.activeCel` are both non-nil, and calls
`applyXbrzFilter(n)`. `exit(plugin)` is a no-op stub.

`applyXbrzFilter(scaleFactor)` runs inside `app.transaction`:

1. Guards on active sprite / cel / image, alerting and returning if any is missing.
2. Builds temp paths from `$TEMP` / `$TMP` / `/tmp` plus `os.time()`:
   `xbrz_input_<t>.png`, `xbrz_output_<t>.png`.
3. `image:saveAs(inputPath)`.
4. Locates the executable via the probe described above; alerts and cleans up if not found.
5. `os.execute('"<exe>" <scale> "<in>" "<out>"')`.
6. `Image{ fromFile=outputPath }`, then creates a **new** `Sprite` at the scaled
   dimensions with the source's `colorMode`, applies `sprite.palettes[1]`, and puts the
   image in a new cel at `Point(0,0)`.
7. Sets `app.activeSprite` to the new sprite, removes both temp files, alerts success.

Note the source sprite is never modified — the result is always a new sprite.

## Testing

There is no automated test suite. The harness is a batch Lua script:

```bash
aseprite --batch --script test-xbrz.lua
```

It checks that the plugin file loads (`dofile`), that `init` and `exit` exist, and that
the executable-discovery loop finds a working binary; if `examples/threeformsPJ2.png` is
present it also runs a real 2x scale end-to-end. That PNG was removed with the example
gallery, so that last stage now self-skips — restore it from git to exercise it.

Beyond that, verify in the GUI: open `examples/aseprite_test.ase`, run each scale
factor, confirm the new sprite's dimensions, color mode, and palette.

## Packaging

`.github/workflows/package-aseprite-plugin.yml` zips `package.json` and
`xbrz-filter.lua` into `xbrz-filter.aseprite-extension`, uploads it as an artifact, and
attaches it to published releases. It triggers on changes to `aseprite-plugin/**` or the
workflow itself, on PRs touching those paths, on `workflow_dispatch`, and on release.

Note the archive contains **only** those two files — a new plugin file must be added to
the `zip` command in the workflow or it will not ship.

## Conventions

- Lua for the plugin, targeting the Aseprite scripting API (`app.*`, `Sprite`, `Image`,
  `Point`, `plugin:newCommand`).
- User-facing errors go through `app.alert`, and always clean up temp files before returning.
- GPL-3.0-or-later, matching xBRZ and the original xbrzscale.

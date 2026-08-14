# xbrzscale — archived

This repository is an archive. It no longer contains working code.

It was a series of experiments in applying **xBRZ** pixel-art upscaling
(<https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms#xBR_family>) to a pixel-art
workflow, built up and then stripped back down:

| Experiment | Fate |
|---|---|
| C++ CLI (`xbrzscale`) wrapping vendored xBRZ 1.8 over SDL2 | removed |
| C API + shared library for FFI | removed |
| Python package (ctypes + numpy + Pillow) | removed |
| CMake / preset / Makefile build system, cross-platform CI | removed |
| Aseprite extension shelling out to the CLI | removed |

The successor — and the point of the whole series — is a **fork of Aseprite with xBRZ
integrated natively**, rather than an extension shipping pixels out to a subprocess and
back.

## What's here

- **[REMOVED.md](REMOVED.md)** — a detailed record of everything deleted: purpose, file
  inventories, verbatim source for the small files, algorithm and API descriptions,
  dependency pins, build flags and the reasons for them, and per-component notes on
  recreating it. Read this first.
- `examples/aseprite_test.ase` — an Aseprite test sprite, kept for future work.
- `License.txt` — GPL-3.0.

## Recovering the code

Git history is intact; REMOVED.md is the summary, not the backup.

| Want | Commit |
|---|---|
| The Aseprite extension | `3d1abd6` |
| CLI, Python wrapper, build system | `138f912` |

```bash
git show 138f912 --stat
git checkout 138f912 -- <paths>
```

Note that `master` predates the `aseprite` branch additions (`CMakePresets.json`, the
SDL2 bump to `release-2.32.10`) — `138f912` is the complete ref, not `master`.

## License

GPL-3.0-or-later. The xBRZ algorithm is from <https://sourceforge.net/projects/xbrz/>.
The original `xbrzscale` CLI is Copyright (c) 2014 Przemysław Grzywacz
<nexather@gmail.com>; upstream is <https://github.com/atheros/xbrzscale>.

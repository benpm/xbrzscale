# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**This repository is an archive and contains no working code.** There is nothing to
build, run, or test here.

It held a series of experiments in applying xBRZ pixel-art upscaling to a pixel-art
workflow: a C++ CLI over SDL2 wrapping vendored xBRZ 1.8, a C API and shared library,
a Python ctypes package, a CMake/Makefile build system with cross-platform CI, and an
Aseprite extension that shelled out to the CLI. All of it was removed in two passes.

The successor product is a **fork of Aseprite with xBRZ integrated natively** — which
lives elsewhere, not in this repo.

## Contents

```
REMOVED.md                  the record of everything deleted (~900 lines)
examples/aseprite_test.ase  Aseprite test sprite, kept for future work
License.txt                 GPL-3.0
README.md                   archive notice
.gitignore                  retained; entries are inert until code is restored
```

## Working here

Almost any request about this repo is really a request about code that was removed.
Before answering from the docs:

- **`REMOVED.md` is the authority on what existed.** It carries verbatim source for the
  small files (the C API, `libxbrzscale.h`, both Makefiles, the plugin's Lua and
  manifest), algorithm-level descriptions of the larger ones, dependency pins, and the
  reasoning behind non-obvious build flags. It is organized §1–§13 by component.
- **Git is the authority on the code itself.** `138f912` holds everything (CLI, Python,
  build system, plugin); `3d1abd6` holds the plugin-only tree. `master` is *not* a
  complete ref — `CMakePresets.json` and the SDL2 `release-2.32.10` bump were added on
  the `aseprite` branch only. Use `git show <commit>:<path>` to read a removed file
  rather than reconstructing it from REMOVED.md prose.

If asked to restore something, prefer `git checkout <commit> -- <paths>` over retyping
from the notes, and re-read REMOVED.md for the caveats attached to that component —
several document known bugs preserved from upstream (the `setEnableOutput` parameter
that is ignored, a leak in `libxbrzscale::scale`, the plugin's incorrect `os.execute`
return check).

Do not restore the vendored `xbrz/` sources by hand; fetch xBRZ 1.8 from
<https://sourceforge.net/projects/xbrz/files/xBRZ/>.

# GitHub Actions Workflows

## build.yml

Automated build workflow for xbrzscale that runs on:
- **Push to master/main branches** - Validates that the code builds correctly
- **Pull requests** - Ensures PRs don't break the build
- **Release publication** - Creates standalone executables and uploads them to the release

### Build Matrix

The workflow builds on three platforms:

| Platform | Runner | Outputs |
|----------|--------|---------|
| Windows | `windows-latest` | `xbrzscale.exe`, SDL2 DLLs, `xbrz_shared.dll` |
| Linux | `ubuntu-latest` | `xbrzscale`, `libxbrz_shared.so` |
| macOS | `macos-latest` | `xbrzscale`, `libxbrz_shared.dylib` |

### Artifacts

Each build uploads artifacts that can be downloaded from the Actions tab:
- `xbrzscale-windows` - Windows executable and dependencies
- `xbrzscale-linux` - Linux binary and shared library
- `xbrzscale-macos` - macOS binary and shared library

### Releases

When you create a GitHub release (or tag with `git tag v1.0.0 && git push --tags`):

1. The workflow builds executables for all platforms
2. Archives are created:
   - `xbrzscale-windows.zip`
   - `xbrzscale-linux.tar.gz`
   - `xbrzscale-macos.tar.gz`
3. Archives are automatically uploaded to the release

### Creating a Release

To create a new release with binaries:

```bash
# Tag the commit
git tag v1.0.0
git push origin v1.0.0

# Create release on GitHub
gh release create v1.0.0 --title "Release v1.0.0" --notes "Release notes here"
```

The workflow will automatically build and upload the binaries to the release.

### Local Testing

To verify the workflow configuration locally:

```bash
# Install act (GitHub Actions local runner)
# https://github.com/nektos/act

# Test the build job
act push -j build-windows
```

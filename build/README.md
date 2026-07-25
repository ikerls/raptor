# Build Scripts and Image Variants

The image uses a shared build stage and explicit final targets. Scripts run in
numerical order within their directory.

## Directory Layout

```text
build/
├── common/                    # Runs for every image
│   ├── 10-build.sh
│   └── 20-*.sh
├── variants/
│   └── nvidia/
│       └── 40-nvidia.sh       # Runs only for the NVIDIA target
├── 00-image-info.sh           # Writes final image identity
├── clean-stage.sh             # Cleans each final image before linting
└── copr-helpers.sh             # Shared helper functions
```

The published variants are:

- `raptor:stable` — standard image; runs only `build/common/*.sh`.
- `raptor-nvidia:stable` — runs the common scripts, then
  `build/variants/nvidia/*.sh`.

The `standard` Containerfile target is last and is therefore the safe default
for a direct `podman build .`.

## Local Builds

```bash
just build
just build-nvidia

# Equivalent explicit commands
just build raptor stable standard
just build raptor-nvidia stable nvidia
```

## Adding Scripts

Add changes needed by every image to `build/common/`. Add hardware- or
purpose-specific changes beneath `build/variants/<variant>/`.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "::group:: ===$(basename "$0")==="

dnf5 install -y package-name

echo "::endgroup::"
```

Use the numbered convention (`10-*`, `20-*`, `30-*`, and so on), keep one
purpose per script, use `dnf5 -y` for non-interactive package operations, and
remove or disable temporary repositories before the script exits.

To add another image variant:

1. Create `build/variants/<variant>/` with numbered scripts.
2. Add a final Containerfile target inheriting from `shared`.
3. Add the variant-to-flavor mapping in the `build` Just recipe.
4. Add the image suffix and flavor to the workflow matrix.
5. Add the package to the cleanup matrix.

All scripts run as root with the repository build context mounted at `/ctx`.

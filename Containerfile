###############################################################################
# PROJECT NAME CONFIGURATION
###############################################################################
# Name: raptor
#
# IMPORTANT: Change "finpilot" above to your desired project name.
# This name should be used consistently throughout the repository in:
#   - Justfile: export image_name := env("IMAGE_NAME", "your-name-here")
#   - README.md: # your-name-here (title)
#   - artifacthub-repo.yml: repositoryID: your-name-here
#   - custom/ujust/README.md: localhost/your-name-here:stable (in bootc switch example)
#
# The project name defined here is the single source of truth for your
# custom image's identity. When changing it, update all references above
# to maintain consistency.
###############################################################################

###############################################################################
# MULTI-STAGE BUILD ARCHITECTURE
###############################################################################
# This Containerfile follows the Bluefin architecture pattern as implemented in
# @projectbluefin/distroless. The architecture layers OCI containers together:
#
# 1. Context Stage (ctx) - Combines resources from:
#    - Local build scripts and custom files
#    - @projectbluefin/common - Desktop configuration shared with Aurora
#    - @ublue-os/brew - Homebrew integration
#
# 2. Base Image Options:
#    - `ghcr.io/ublue-os/silverblue-main:latest` (Fedora and GNOME)
#    - `ghcr.io/ublue-os/base-main:latest` (Fedora and no desktop
#    - `quay.io/centos-bootc/centos-bootc:stream10 (CentOS-based)`
#
# See: https://docs.projectbluefin.io/contributing/ for architecture diagram
###############################################################################

# Context stage - combine local and imported OCI container resources
FROM scratch AS ctx

COPY build /build
COPY custom /custom
# Copy from OCI containers to distinct subdirectories to avoid conflicts
# Note: Renovate can automatically update these :latest tags to SHA-256 digests for reproducibility
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:47abba6e2a15e36efcb18255fefa7c65673337404719a925d74409c6e080929e /system_files /oci/common
COPY --from=ghcr.io/ublue-os/brew:latest@sha256:7646a12d0369270ba479bde05d69e273af966a55178f283b0f717381d086ca7a /system_files /oci/brew

# Base Image - GNOME included
FROM ghcr.io/ublue-os/silverblue-main:latest@sha256:c2b7b2a380fdf55958e9ea6bcb09afdeb19b13856ca0711ab687ce6ca6594467
FROM ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable@sha256:fa640c65445b766ec6639f960f0e6ae5a1cf95fcda2ec6ac029071ae0e7061d0

## Alternative base images, no desktop included (uncomment to use):
# FROM ghcr.io/ublue-os/base-main:latest
# FROM quay.io/centos-bootc/centos-bootc:stream10

## Alternative GNOME OS base image (uncomment to use):
# FROM quay.io/gnome_infrastructure/gnome-build-meta:gnomeos-nightly

### /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

RUN rm /opt && mkdir /opt

### MODIFICATIONS
## Make modifications desired in your image and install packages by modifying the build scripts.
## The following RUN directive mounts the ctx stage which includes:
##   - Local build scripts from /build
##   - Local custom files from /custom
##   - Files from @projectbluefin/common at /oci/common
##   - Files from @projectbluefin/branding at /oci/branding
##   - Files from @ublue-os/artwork at /oci/artwork
##   - Files from @ublue-os/brew at /oci/brew
## Scripts are run in numerical order (10-build.sh, 20-example.sh, etc.)

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    for script in /ctx/build/[0-9]*.sh; do \
        echo "Running ${script}..." && \
        bash "${script}" || exit 1; \
    done
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

###############################################################################
# PROJECT NAME CONFIGURATION
###############################################################################
# Name: raptor
###############################################################################
# MULTI-STAGE BUILD ARCHITECTURE
###############################################################################
# This Containerfile follows the Bluefin architecture pattern as implemented in
# @projectbluefin/distroless. The architecture layers OCI containers together:
#
# 1. Context Stage (ctx) - Combines resources from:
#    - Local build scripts and custom files
#    - @projectbluefin/common - Desktop configuration
#    - @ublue-os/brew - Homebrew integration
#
# 2. Base Image Options (edit the FROM line below):
#    - `quay.io/fedora-ostree-desktops/silverblue:44` (Fedora 44 and GNOME)
#    - `quay.io/fedora-ostree-desktops/base-main:44` (Fedora 44, no desktop)
#    - `quay.io/centos-bootc/centos-bootc:stream10` (CentOS-based)
#
# See: https://docs.projectbluefin.io/contributing/ for architecture diagram
###############################################################################

# OCI context images - imported below and pinned directly in their FROM lines.
# The base image is pinned in the FROM line below and updated by Renovate.
FROM ghcr.io/projectbluefin/common:latest@sha256:df2fa93dac84cda91d568bd694e5051abbbdba37bf3d54a6cc15cdc80e645e2c AS common
FROM ghcr.io/ublue-os/brew:latest@sha256:5c5b6dea4b9faaab4d6fa81d7fc4f37f218c8a75a0839c72ae70b268bfdf4b0f AS brew

# Context stage - combine local and imported OCI container resources
FROM scratch AS ctx

COPY build /build
COPY custom /custom

# Copy from OCI containers to distinct subdirectories to avoid conflicts
COPY --from=common /system_files /oci/common
COPY --from=brew /system_files /oci/brew

# Shared image - GNOME included (Fedora official OSTree desktop).
# Both published variants inherit all layers produced by this stage.
FROM quay.io/fedora-ostree-desktops/silverblue:44@sha256:2b8f8279b3c326e131ad6cb64aa416565053d268a5a337807141f353b0354696 AS shared

# Shared identity and build inputs. IMAGE_NAME and IMAGE_FLAVOR are declared
# by each final target so direct target builds receive the correct defaults.
ARG IMAGE_VENDOR=ikerls
ARG UBLUE_IMAGE_TAG=stable
ARG BASE_IMAGE_NAME=silverblue
ARG FEDORA_MAJOR_VERSION=44
ARG VERSION
ARG SOURCE_REPOSITORY=ikerls/raptor
ARG AKMODS_FLAVOR=main

### /opt
## Makes /opt writeable by default. Needs to be here to make the main image
## build strict (no /opt there). This is for downstream images/stuff like k0s.
## If you need /opt as an immutable real directory for build-time packages
## (e.g. google-chrome, docker-desktop), replace the next line with:
RUN rm /opt && mkdir /opt

### MODIFICATIONS
## Make modifications desired in your image and install packages by modifying
## the common or variant build scripts.
## The following RUN directives mount the ctx stage which includes:
##   - Shared build scripts from /build/common
##   - Variant build scripts from /build/variants
##   - Local custom files from /custom
##   - Files from @projectbluefin/common at /oci/common (includes branding/artwork content)
##   - Files from @ublue-os/brew at /oci/brew
## Scripts within each directory are run in numerical order.

# Set dnf options before build scripts (persists across subsequent RUN layers)
RUN dnf5 config-manager setopt keepcache=1 install_weak_deps=0

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=secret,id=GITHUB_TOKEN \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/tmp \
    for script in /ctx/build/common/[1-9]*.sh; do \
        echo "Running ${script}..." && \
        bash "${script}" || exit 1; \
    done

###############################################################################
# NVIDIA VARIANT
###############################################################################
FROM shared AS nvidia

ARG IMAGE_NAME=raptor-nvidia
ARG IMAGE_FLAVOR=nvidia

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=secret,id=GITHUB_TOKEN \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/tmp \
    for script in /ctx/build/variants/nvidia/[1-9]*.sh; do \
        echo "Running ${script}..." && \
        bash "${script}" || exit 1; \
    done

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/00-image-info.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=tmpfs,dst=/boot \
    /ctx/build/clean-stage.sh

CMD ["/sbin/init"]

RUN bootc container lint --fatal-warnings

###############################################################################
# STANDARD VARIANT
#
# Keep this target last so a direct `podman build .` is NVIDIA-free.
###############################################################################
FROM shared AS standard

ARG IMAGE_NAME=raptor
ARG IMAGE_FLAVOR=main

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build/00-image-info.sh

# /run is deliberately not mounted as tmpfs here: clean-stage.sh must remove
# image-layer files such as /run/dnf before bootc lint runs.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=tmpfs,dst=/boot \
    /ctx/build/clean-stage.sh

CMD ["/sbin/init"]

RUN bootc container lint --fatal-warnings

#!/usr/bin/env bash
# Build VLC's contribs for one Apple target and package them (cloudunifi/vlckit, spec 2026-10-31 §6).
# Mirrors buildLibVLC in compileAndBuildVLCKit.sh: same clone, same patches, same tools, same build.sh
# call, plus --package-contribs. build.sh goes on to build libvlc afterwards; that is a by-product here,
# the package in contrib-packages/ is what the workflow uploads.
#
#   ci/contribs.sh <iphoneos|iphonesimulator|appletvos|appletvsimulator|macosx> [aarch64]
set -euo pipefail

PLATFORM="$1"
ARCH="${2:-aarch64}"
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TESTEDHASH=$(sed -n 's/^TESTEDHASH="\([0-9a-f]*\)".*/\1/p' "$ROOT_DIR/compileAndBuildVLCKit.sh")
[ -n "$TESTEDHASH" ] || { echo "TESTEDHASH not found" >&2; exit 2; }

case "$PLATFORM" in
    iphoneos|iphonesimulator)   SDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version) ;;
    appletvos|appletvsimulator) SDK_VERSION=$(xcrun --sdk appletvos --show-sdk-version) ;;
    macosx)                     SDK_VERSION=$(xcrun --sdk macosx --show-sdk-version) ;;
    *) echo "unknown platform $PLATFORM" >&2; exit 2 ;;
esac
ACTUAL_ARCH="$ARCH"; [ "$ARCH" = "aarch64" ] && ACTUAL_ARCH="arm64"

mkdir -p "$ROOT_DIR/libvlc"
cd "$ROOT_DIR/libvlc"
if [ ! -d vlc ]; then
    git clone https://code.videolan.org/videolan/vlc.git --branch master --single-branch vlc
    ( cd vlc && git checkout -B localBranch "$TESTEDHASH" \
        && git -c user.name=ci -c user.email=ci@local am "$ROOT_DIR"/libvlc/patches/*.patch )
fi
VLCROOT="$ROOT_DIR/libvlc/vlc"

PYTHON3_PATH=$(echo /Library/Frameworks/Python.framework/Versions/3.*/bin | awk '{print $1}')
[ -d "$PYTHON3_PATH" ] || PYTHON3_PATH=""
export PATH="${PYTHON3_PATH:+$PYTHON3_PATH:}${VLCROOT}/extras/tools/build/bin:${VLC_PATH:-/opt/homebrew/bin}:/usr/bin:/bin:/usr/sbin:/sbin"
( cd "$VLCROOT/extras/tools" && ./bootstrap && make )

BUILDDIR="$VLCROOT/build-$PLATFORM-$ACTUAL_ARCH"
mkdir -p "$BUILDDIR"
cd "$BUILDDIR"
../extras/package/apple/build.sh --arch="$ARCH" --sdk="${PLATFORM}${SDK_VERSION}" --disable-debug --package-contribs "-j$(sysctl -n hw.ncpu)"

PKG=$(find "$VLCROOT/contrib" -maxdepth 1 -name 'vlc-contrib-*.tar.zst' -print0 | xargs -0 ls -t | head -1)
[ -n "$PKG" ] || { echo "no contrib package produced" >&2; exit 1; }
mkdir -p "$ROOT_DIR/contrib-packages"
cp "$PKG" "$ROOT_DIR/contrib-packages/vlc-contrib-${PLATFORM}-${ACTUAL_ARCH}.tar.zst"
ls -la "$ROOT_DIR/contrib-packages/"

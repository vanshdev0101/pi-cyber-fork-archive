#!/usr/bin/env bash
set -euo pipefail

# Install curl-impersonate as a BUNDLE (not one binary): its profile binaries
# are shell wrappers that exec the engine next to themselves, so the whole
# extracted tree must stay together. The main installer's one-binary-per-entry
# flow cannot express that; this script follows the standalone, digest-pinned
# installer pattern of install-ffuf-wordlist.sh.

TOOLS_DIR="${PI_TOOLS_DIR:-$HOME/.pi/scanners}"
DEST_DIR="$TOOLS_DIR/curl-impersonate"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pi-cyber-curl-impersonate.XXXXXX")"

trap 'rm -rf "$TEMP_DIR"' EXIT

VERSION="v2.3.0"
OS="$(uname -s)"
ARCH="$(uname -m)"
# OS/arch -> upstream asset + pinned SHA-256. Linux uses the glibc (linux-gnu) build.
case "${OS}/${ARCH}" in
  Darwin/arm64)
    ASSET="curl-impersonate-${VERSION}.arm64-macos.tar.gz"
    EXPECTED_SHA256="2dfb4b5733e01ec88f9cc7363696c848d0a2b810584d4c0fac7719f82b985f8f" ;;
  Linux/x86_64)
    ASSET="curl-impersonate-${VERSION}.x86_64-linux-gnu.tar.gz"
    EXPECTED_SHA256="5e77cb12217158f118ead21ab550791788e553fb140d03a49d74d08308ebdb06" ;;
  *)
    echo "pi-cyber: unsupported OS/arch for curl-impersonate: ${OS}/${ARCH}" >&2
    exit 1 ;;
esac

SOURCE_URL="https://github.com/lexiforest/curl-impersonate/releases/download/${VERSION}/${ASSET}"

ARCHIVE="$TEMP_DIR/$ASSET"
curl --fail --location --proto '=https' --tlsv1.2 "$SOURCE_URL" --output "$ARCHIVE"
ACTUAL_SHA256="$(shasum -a 256 "$ARCHIVE" | cut -d ' ' -f 1)"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "pi-cyber: curl-impersonate SHA-256 mismatch; refusing installation" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
tar -xzf "$ARCHIVE" -C "$DEST_DIR"
chmod +x "$DEST_DIR"/*

# Prove the engine runs and that impersonation is compiled in before recording.
if ! "$DEST_DIR/curl-impersonate" --version | grep -q "IMPERSONATE"; then
  echo "pi-cyber: curl-impersonate did not verify post-install; refusing" >&2
  exit 1
fi

echo "pi-cyber: curl-impersonate $VERSION installed at $DEST_DIR"

#!/bin/bash
# Frame Bridge installer for macOS.
#
# Run it by pasting this single line into Terminal:
#   curl -fsSL https://raw.githubusercontent.com/tony-motion/frame-bridge-releases/main/install.sh | bash
#
# It installs, for your user account only (no admin password):
#   • the Frame Bridge Receiver panel for After Effects
#   • the Frame Bridge plugin files for Figma
# and turns on the After Effects setting that lets test panels load.
# Running it again reinstalls the latest build.
#
# Offline option: pass a downloaded package instead of fetching from GitHub:
#   bash install.sh ~/Downloads/frame-bridge-0.1.0.zip
set -euo pipefail

FEED_URL="https://raw.githubusercontent.com/tony-motion/frame-bridge-releases/main/latest.json"
SUPPORT="$HOME/Library/Application Support/Frame Bridge"
EXT_PARENT="$HOME/Library/Application Support/Adobe/CEP/extensions"
EXT="$EXT_PARENT/com.framebridge.receiver"
PLUGIN="$SUPPORT/Figma Plugin"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
step() { printf '  • %s\n' "$1"; }
fail() { printf '\n\033[31mFrame Bridge could not be installed:\033[0m %s\n' "$1" >&2; exit 1; }

echo
bold "FRAME BRIDGE — installer"
echo

[ "$(uname)" = "Darwin" ] || fail "this installer is for macOS."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -n "${1:-}" ]; then
  [ -f "$1" ] || fail "can't find the package file: $1"
  step "Installing from $1"
  cp "$1" "$TMP/frame-bridge.zip"
else
  step "Checking for the latest build…"
  curl -fsSL "$FEED_URL?t=$(date +%s)" -o "$TMP/latest.json" || fail "couldn't reach GitHub. Check your internet connection and try again."

  # Read the release notice with macOS's built-in JavaScript (no extra tools needed).
  read_field() {
    /usr/bin/osascript -l JavaScript -e 'function run(a){var s=$.NSString.stringWithContentsOfFileEncodingError(a[0],4,null).js;var o=JSON.parse(s);return a[1].split(".").reduce(function(v,k){return v[k]},o)}' "$TMP/latest.json" "$1"
  }
  URL="$(read_field package.url)"
  SHA="$(read_field package.sha256)"
  step "Latest build: $(read_field version)"

  step "Downloading…"
  curl -fL --progress-bar "$URL" -o "$TMP/frame-bridge.zip" || fail "the download didn't finish. Try again."
  echo "$SHA  $TMP/frame-bridge.zip" | /usr/bin/shasum -a 256 -c - >/dev/null 2>&1 || fail "the download doesn't match its fingerprint, so it wasn't installed. Try again."
fi

/usr/bin/ditto -x -k "$TMP/frame-bridge.zip" "$TMP/pkg" || fail "the download couldn't be unpacked."
[ -f "$TMP/pkg/receiver/CSXS/manifest.xml" ] && [ -f "$TMP/pkg/figma-plugin/manifest.json" ] || fail "the download is incomplete."
VERSION="$(/usr/bin/sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$TMP/pkg/receiver/payload/version.json" | head -1)"

step "Installing the After Effects Receiver…"
mkdir -p "$EXT_PARENT"
rm -rf "$EXT"
/usr/bin/ditto "$TMP/pkg/receiver" "$EXT"
# A fresh install starts from the copy that came with it.
rm -f "$SUPPORT/receiver/current.json"

step "Installing the Figma plugin files…"
mkdir -p "$PLUGIN"
/usr/bin/ditto "$TMP/pkg/figma-plugin" "$PLUGIN"

step "Allowing After Effects to load the Receiver panel…"
if [ -z "${FB_TEST_INSTALL:-}" ]; then
  for v in 10 11 12 13 14; do
    defaults write "com.adobe.CSXS.$v" PlayerDebugMode 1
  done
  printf '%s' "$PLUGIN/manifest.json" | pbcopy
fi

echo
bold "Installed Frame Bridge $VERSION."
echo
echo "Two one-time steps:"
echo
echo "  1. After Effects: quit and reopen it, then choose"
echo "     Window ▸ Extensions ▸ Frame Bridge Receiver, and dock the panel."
echo
echo "  2. Figma desktop: Plugins ▸ Development ▸ Import plugin from manifest…"
echo "     In the file dialog press ⌘⇧G, then ⌘V (the location is already"
echo "     copied), press Return, and click Open."
echo
echo "From now on, the Receiver keeps itself and the Figma plugin up to date."
echo

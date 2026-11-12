#!/bin/bash
# Removes Frame Bridge from this Mac (your After Effects projects and their
# imported images are not touched).
set -euo pipefail
rm -rf "$HOME/Library/Application Support/Adobe/CEP/extensions/com.framebridge.receiver"
rm -rf "$HOME/Library/Application Support/Frame Bridge"
echo "Frame Bridge was removed."
echo "In Figma, also remove it under Plugins ▸ Development ▸ Manage plugins in development."
echo "Reports and diagnostics in Documents ▸ Frame Bridge were kept; delete that folder if you don't need them."

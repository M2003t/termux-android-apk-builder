#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

echo "== Termux AppForge Clean =="

if [ -d "$BUILD_DIR" ]; then
    echo "Removing generated build artifacts..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

echo
echo "CLEAN SUCCESSFUL"
echo "Build environment is ready for a fresh build."

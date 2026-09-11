#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK="$PROJECT_DIR/build/Termux-AppForge.apk"

if [ ! -f "$APK" ]; then
    echo "ERROR: APK not found."
    echo "Build the project first:"
    echo "bash scripts/build_android.sh"
    exit 1
fi

echo "== Verifying Termux AppForge APK =="
echo

echo "[1/3] Verifying APK signature..."
apksigner verify --verbose "$APK"

echo
echo "[2/3] Reading APK metadata..."
aapt dump badging "$APK" | head -n 20

echo
echo "[3/3] Checking native library..."
unzip -l "$APK" | grep "lib/arm64-v8a/libmain.so"

echo
echo "======================================"
echo "APK VERIFICATION PASSED"
echo "======================================"

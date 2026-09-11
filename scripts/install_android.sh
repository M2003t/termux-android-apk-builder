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

echo "Opening Android installer..."
termux-open "$APK"

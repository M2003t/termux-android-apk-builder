#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Termux AppForge Full Android Validation =="
echo

echo "[1/5] Cleaning build environment..."
bash "$PROJECT_DIR/scripts/clean_android.sh"

echo
echo "[2/5] Building APK..."
bash "$PROJECT_DIR/scripts/build_android.sh"

echo
echo "[3/5] Verifying APK artifact..."
bash "$PROJECT_DIR/scripts/verify_android.sh"

echo
echo "[4/5] Installing current build..."
bash "$PROJECT_DIR/scripts/install_android.sh"

echo
echo "Complete the Android installation/update."
echo "Then return to Termux and press Enter to continue."
read -r

echo
echo "[5/5] Running runtime smoke test..."
bash "$PROJECT_DIR/scripts/smoke_android.sh"

echo
echo "======================================"
echo "FULL ANDROID VALIDATION PASSED"
echo "======================================"

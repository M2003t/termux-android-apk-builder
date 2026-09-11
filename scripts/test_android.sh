#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Termux AppForge Full Android Validation =="
echo

echo "[1/4] Cleaning build environment..."
bash "$PROJECT_DIR/scripts/clean_android.sh"

echo
echo "[2/4] Building APK..."
bash "$PROJECT_DIR/scripts/build_android.sh"

echo
echo "[3/4] Verifying APK artifact..."
bash "$PROJECT_DIR/scripts/verify_android.sh"

echo
echo "[4/4] Runtime smoke test..."
bash "$PROJECT_DIR/scripts/smoke_android.sh"

echo
echo "======================================"
echo "FULL ANDROID VALIDATION PASSED"
echo "======================================"

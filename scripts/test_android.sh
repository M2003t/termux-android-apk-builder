#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_DIR/local_data/logs"

mkdir -p "$LOG_DIR"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/android-validation_$TIMESTAMP.log"

START_TIME="$(date +%s)"

BUILD_STATUS="NOT RUN"
VERIFY_STATUS="NOT RUN"
INSTALL_STATUS="NOT RUN"
SMOKE_STATUS="NOT RUN"
BUILD_ID="UNKNOWN"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "== Termux AppForge Full Android Validation =="
echo "Started: $(date)"
echo "Log: $LOG_FILE"
echo

echo "[1/5] Cleaning build environment..."
bash "$PROJECT_DIR/scripts/clean_android.sh"

echo
echo "[2/5] Building APK..."
bash "$PROJECT_DIR/scripts/build_android.sh"
BUILD_STATUS="PASS"

echo
echo "[3/5] Verifying APK artifact..."
bash "$PROJECT_DIR/scripts/verify_android.sh"
VERIFY_STATUS="PASS"

BUILD_ID="$(unzip -p "$PROJECT_DIR/build/Termux-AppForge.apk" assets/build_id.txt 2>/dev/null || true)"

echo
echo "[4/5] Installing current build..."
bash "$PROJECT_DIR/scripts/install_android.sh"

echo
echo "Waiting for Android installer..."
sleep 3

echo
echo "Complete the Android installation/update first."
echo "Do NOT continue while the installer is still open."
echo
echo "After installation finishes, return to Termux."
echo "Type: installed"
echo

while true; do
    read -r INSTALL_CONFIRMATION

    if [ "$INSTALL_CONFIRMATION" = "installed" ]; then
        break
    fi

    echo "Please complete the installation and type: installed"
done

INSTALL_STATUS="PASS"

echo
echo "[5/5] Running runtime smoke test..."
bash "$PROJECT_DIR/scripts/smoke_android.sh"
SMOKE_STATUS="PASS"

END_TIME="$(date +%s)"
DURATION="$((END_TIME - START_TIME))"

echo
echo "======================================"
echo "VALIDATION SUMMARY"
echo "======================================"
echo "Build ID:           $BUILD_ID"
echo "Build:              $BUILD_STATUS"
echo "APK Verification:   $VERIFY_STATUS"
echo "Install Checkpoint: $INSTALL_STATUS"
echo "Runtime Smoke Test: $SMOKE_STATUS"
echo "Duration:           ${DURATION}s"
echo "Result:             PASS"
echo "======================================"

echo
echo "FULL ANDROID VALIDATION PASSED"
echo "Finished: $(date)"
echo "Log saved to:"
echo "$LOG_FILE"

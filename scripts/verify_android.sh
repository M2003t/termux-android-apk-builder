#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK="$PROJECT_DIR/build/Termux-AppForge.apk"

EXPECTED_PACKAGE="com.m2003t.termuxappforge"
EXPECTED_VERSION_CODE="1"
EXPECTED_VERSION_NAME="0.1.0"
EXPECTED_LABEL="Termux AppForge"

fail() {
    echo
    echo "VERIFICATION FAILED: $1"
    exit 1
}

if [ ! -f "$APK" ]; then
    fail "APK not found. Run: bash scripts/build_android.sh"
fi

echo "== Verifying Termux AppForge APK =="
echo

echo "[1/7] Verifying APK signature..."
apksigner verify "$APK" || fail "APK signature is invalid."

BADGING="$(aapt dump badging "$APK")"

echo
echo "[2/7] Verifying package name..."
echo "$BADGING" | grep -q "package: name='$EXPECTED_PACKAGE'" \
    || fail "Unexpected package name."
echo "PASS: $EXPECTED_PACKAGE"

echo
echo "[3/7] Verifying version..."
echo "$BADGING" | grep -q "versionCode='$EXPECTED_VERSION_CODE'" \
    || fail "Unexpected versionCode."
echo "$BADGING" | grep -q "versionName='$EXPECTED_VERSION_NAME'" \
    || fail "Unexpected versionName."
echo "PASS: $EXPECTED_VERSION_NAME ($EXPECTED_VERSION_CODE)"

echo
echo "[4/7] Verifying application label..."
echo "$BADGING" | grep -q "application-label:'$EXPECTED_LABEL'" \
    || echo "$BADGING" | grep -q "application: label='$EXPECTED_LABEL'" \
    || fail "Application label is missing or incorrect."
echo "PASS: $EXPECTED_LABEL"

echo
echo "[5/7] Verifying architecture..."
echo "$BADGING" | grep -q "native-code: 'arm64-v8a'" \
    || fail "arm64-v8a architecture not found."
echo "PASS: arm64-v8a"

echo
echo "[6/7] Verifying native library..."
unzip -l "$APK" | grep -q "lib/arm64-v8a/libmain.so" \
    || fail "libmain.so not found in APK."
echo "PASS: libmain.so"

echo
echo "[7/7] Verifying Build ID..."

BUILD_ID="$(unzip -p "$APK" assets/build_id.txt 2>/dev/null || true)"

if [ -z "$BUILD_ID" ]; then
    fail "Build ID not found inside APK."
fi

if ! echo "$BUILD_ID" | grep -qE '^[0-9]{8}-[0-9]{6}$'; then
    fail "Build ID format is invalid: $BUILD_ID"
fi

echo "PASS: Build ID $BUILD_ID"

echo
echo "======================================"
echo "ALL APK ACCEPTANCE CHECKS PASSED"
echo "Build ID: $BUILD_ID"
echo "======================================"

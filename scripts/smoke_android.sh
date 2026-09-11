#!/data/data/com.termux/files/usr/bin/bash
set -e

PACKAGE="com.m2003t.termuxappforge"
ACTIVITY="android.app.NativeActivity"

fail() {
    echo
    echo "SMOKE TEST FAILED: $1"
    exit 1
}

echo "== Termux AppForge Runtime Smoke Test =="
echo

echo "[1/2] Checking installed package..."

PACKAGE_PATH="$(pm path "$PACKAGE" 2>/dev/null || true)"

if [ -z "$PACKAGE_PATH" ]; then
    fail "Package is not installed: $PACKAGE"
fi

echo "PASS: Package is installed"
echo "$PACKAGE_PATH"

echo
echo "[2/2] Launching application..."

am start \
    -n "$PACKAGE/$ACTIVITY" \
    >/dev/null 2>&1 \
    || fail "Android could not launch the application."

echo "PASS: Launch request accepted"

echo
echo "======================================"
echo "RUNTIME SMOKE TEST PASSED"
echo "======================================"

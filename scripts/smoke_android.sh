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

echo "[1/1] Launching application..."

LAUNCH_OUTPUT="$(am start -W -n "$PACKAGE/$ACTIVITY" 2>&1)" || {
    echo "$LAUNCH_OUTPUT"
    fail "Android could not launch the application."
}

echo "$LAUNCH_OUTPUT"

if echo "$LAUNCH_OUTPUT" | grep -qiE \
    'Error|Exception|does not exist|unable to resolve|Permission Denial'; then
    fail "Android reported a launch error."
fi

if ! echo "$LAUNCH_OUTPUT" | grep -qiE \
    'Status: ok|Activity:|ThisTime:|TotalTime:'; then
    fail "Launch result could not be confirmed."
fi

echo
echo "PASS: Application launch confirmed"

echo
echo "======================================"
echo "RUNTIME SMOKE TEST PASSED"
echo "======================================"

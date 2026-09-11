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

set +e
LAUNCH_OUTPUT="$(am start -W -n "$PACKAGE/$ACTIVITY" 2>&1)"
EXIT_CODE=$?
set -e

echo "$LAUNCH_OUTPUT"

if [ "$EXIT_CODE" -ne 0 ]; then
    fail "Android activity manager returned exit code $EXIT_CODE."
fi

if echo "$LAUNCH_OUTPUT" | grep -qiE \
    'Error|Exception|does not exist|unable to resolve|Permission Denial|SecurityException'; then
    fail "Android reported a launch error."
fi

if ! echo "$LAUNCH_OUTPUT" | grep -q "Starting: Intent"; then
    fail "Launch request was not confirmed."
fi

echo
echo "PASS: Android accepted the launch request"

if echo "$LAUNCH_OUTPUT" | grep -q "current task has been brought to the front"; then
    echo "INFO: Application was already running and was brought to the foreground."
else
    echo "INFO: Application launch request was issued successfully."
fi

echo
echo "======================================"
echo "RUNTIME SMOKE TEST PASSED"
echo "======================================"

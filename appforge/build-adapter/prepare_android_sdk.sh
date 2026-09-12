#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

SDK_ROOT="${1:?SDK root is required}"

CMDLINE_VERSION="15859902"
CMDLINE_SHA256="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"

WORK_ROOT="$HOME/.cache/termux-appforge"
DOWNLOAD_DIR="$WORK_ROOT/downloads"

ZIP="$DOWNLOAD_DIR/commandlinetools-linux-${CMDLINE_VERSION}_latest.zip"

URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_VERSION}_latest.zip"

SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$SDK_ROOT"

echo "== Preparing Android SDK =="

if [ ! -x "$SDKMANAGER" ]; then
    echo "Installing Android command-line tools..."

    if [ ! -f "$ZIP" ]; then
        curl --fail --location "$URL" -o "$ZIP"
    fi

    echo "$CMDLINE_SHA256  $ZIP" | sha256sum -c -

    TMP="$WORK_ROOT/cmdline-tools-temp"

    rm -rf "$TMP"
    mkdir -p "$TMP"

    unzip -q "$ZIP" -d "$TMP"

    mkdir -p "$SDK_ROOT/cmdline-tools"
    rm -rf "$SDK_ROOT/cmdline-tools/latest"

    mv \
        "$TMP/cmdline-tools" \
        "$SDK_ROOT/cmdline-tools/latest"

    rm -rf "$TMP"
fi

echo "Accepting required Android SDK licenses..."

set +o pipefail

yes | "$SDKMANAGER" \
    --sdk_root="$SDK_ROOT" \
    --licenses >/dev/null

STATUS=${PIPESTATUS[1]}

set -o pipefail

if [ "$STATUS" -ne 0 ]; then
    echo "ERROR: Android SDK license setup failed."
    exit 1
fi

echo "Installing pinned Android SDK components..."

"$SDKMANAGER" \
    --sdk_root="$SDK_ROOT" \
    "platforms;android-36" \
    "build-tools;35.0.0" \
    "platform-tools"

BT="$SDK_ROOT/build-tools/35.0.0"

echo "Replacing x86-64 build tools with Termux ARM64 tools..."

install -m 755 "$PREFIX/bin/aapt2"    "$BT/aapt2"
install -m 755 "$PREFIX/bin/aidl"     "$BT/aidl"
install -m 755 "$PREFIX/bin/zipalign" "$BT/zipalign"

for TOOL in aapt2 aidl zipalign; do
    INFO="$(file "$BT/$TOOL")"

    echo "$INFO"

    if ! echo "$INFO" | grep -qiE 'arm64|aarch64'; then
        echo "ERROR: $TOOL is not ARM64."
        exit 1
    fi
done

if [ ! -f "$SDK_ROOT/platforms/android-36/android.jar" ]; then
    echo "ERROR: Android API 36 platform is missing."
    exit 1
fi

echo "Android SDK adapter ready."

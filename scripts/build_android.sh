#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJECT_DIR/src"
ANDROID_DIR="$PROJECT_DIR/android"
BUILD_DIR="$PROJECT_DIR/build"
LOCAL_DIR="$PROJECT_DIR/local_data"

NDK="$HOME/android-ndk"
ANDROID_JAR="$HOME/android-sdk/android.jar"
NAYLIB_PATH="$(find "$HOME/.nimble/pkgs2" -maxdepth 1 -type d -name 'naylib-*' | head -n 1)"

LIB_DIR="$BUILD_DIR/lib/arm64-v8a"
KEYSTORE="$LOCAL_DIR/debug.keystore"

echo "== Termux AppForge Android Builder =="
echo

mkdir -p "$LIB_DIR"
mkdir -p "$LOCAL_DIR"

if [ -z "$NAYLIB_PATH" ]; then
    echo "ERROR: Naylib was not found."
    exit 1
fi

if [ ! -f "$ANDROID_JAR" ]; then
    echo "ERROR: Android SDK android.jar was not found:"
    echo "$ANDROID_JAR"
    exit 1
fi

if [ ! -d "$NDK" ]; then
    echo "ERROR: Android NDK environment was not found:"
    echo "$NDK"
    exit 1
fi

echo "[1/5] Compiling Nim + Raylib..."

nim c \
    --app:lib \
    --noMain \
    --path:"$PREFIX/lib/nim/lib/pure" \
    --path:"$NAYLIB_PATH" \
    --path:"$SRC_DIR" \
    -d:AndroidNdk="$NDK" \
    --passC:"-I$NDK/sysroot/usr/include" \
    --out:"$LIB_DIR/libmain.so" \
    "$SRC_DIR/androidentry.nim"

echo
echo "[2/5] Creating APK..."

rm -f \
    "$BUILD_DIR/unsigned.apk" \
    "$BUILD_DIR/aligned.apk" \
    "$BUILD_DIR/Termux-AppForge.apk"

aapt2 link \
    --manifest "$ANDROID_DIR/AndroidManifest.xml" \
    -I "$ANDROID_JAR" \
    -o "$BUILD_DIR/unsigned.apk"

(
    cd "$BUILD_DIR"
    zip -q -u unsigned.apk lib/arm64-v8a/libmain.so
)

echo
echo "[3/5] Aligning APK..."

zipalign -f 4 \
    "$BUILD_DIR/unsigned.apk" \
    "$BUILD_DIR/aligned.apk"

echo
echo "[4/5] Preparing signing key..."

if [ ! -f "$KEYSTORE" ]; then
    if [ -f "$HOME/.debug.keystore" ]; then
        cp "$HOME/.debug.keystore" "$KEYSTORE"
    else
        keytool -genkeypair \
            -keystore "$KEYSTORE" \
            -storepass android \
            -alias debug \
            -keypass android \
            -keyalg RSA \
            -keysize 2048 \
            -validity 10000 \
            -dname "CN=Termux AppForge Debug"
    fi
fi

echo
echo "[5/5] Signing APK..."

apksigner sign \
    --ks "$KEYSTORE" \
    --ks-key-alias debug \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out "$BUILD_DIR/Termux-AppForge.apk" \
    "$BUILD_DIR/aligned.apk"

apksigner verify "$BUILD_DIR/Termux-AppForge.apk"

echo
echo "======================================"
echo "BUILD SUCCESSFUL"
echo
echo "APK:"
echo "$BUILD_DIR/Termux-AppForge.apk"
echo "======================================"

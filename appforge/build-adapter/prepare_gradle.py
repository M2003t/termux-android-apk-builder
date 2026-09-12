from pathlib import Path
import shutil
import sys

if len(sys.argv) != 3:
    print("Usage: prepare_gradle.py <staging-dir> <native-dir>")
    sys.exit(1)

staging = Path(sys.argv[1])
native = Path(sys.argv[2])

gradle_files = [
    staging / "app" / "build.gradle",
    staging / "terminal-emulator" / "build.gradle",
    staging / "termux-shared" / "build.gradle",
]


def remove_balanced_block(text, keyword):
    while True:
        pos = text.find(keyword)

        if pos == -1:
            return text

        brace = text.find("{", pos)

        if brace == -1:
            raise RuntimeError(f"Opening brace not found for {keyword}")

        depth = 0
        end = None

        for i in range(brace, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1

                if depth == 0:
                    end = i + 1
                    break

        if end is None:
            raise RuntimeError(f"Could not parse block: {keyword}")

        text = text[:pos] + text[end:]


for path in gradle_files:
    text = path.read_text()

    # AppForge provides the native libraries itself.
    text = "\n".join(
        line
        for line in text.splitlines()
        if "ndkVersion =" not in line
    )

    text = remove_balanced_block(
        text,
        "externalNativeBuild {"
    )

    path.write_text(text + "\n")


app_gradle = staging / "app" / "build.gradle"
text = app_gradle.read_text()

# AppForge currently produces ARM64 native libraries only.
text = text.replace(
    "include 'x86', 'x86_64', 'armeabi-v7a', 'arm64-v8a'",
    "include 'arm64-v8a'"
)

text = text.replace(
    "universalApk true",
    "universalApk false"
)

# Native bootstrap is already embedded by AppForge.
marker = "afterEvaluate {\n    android.applicationVariants.all"
pos = text.find(marker)

if pos != -1:
    brace = text.find("{", pos)
    depth = 0
    end = None

    for i in range(brace, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1

            if depth == 0:
                end = i + 1
                break

    if end is None:
        raise RuntimeError("Could not remove bootstrap dependency block")

    text = text[:pos] + text[end:]

app_gradle.write_text(text)


jni_dir = (
    staging
    / "app"
    / "src"
    / "main"
    / "jniLibs"
    / "arm64-v8a"
)

jni_dir.mkdir(parents=True, exist_ok=True)

libraries = [
    "libtermux.so",
    "liblocal-socket.so",
    "libtermux-bootstrap.so",
]

for name in libraries:
    source = native / name

    if not source.exists():
        raise RuntimeError(f"Missing native library: {source}")

    shutil.copy2(source, jni_dir / name)

print("Gradle staging adapted for AppForge.")
print("Target ABI: arm64-v8a")
print("Native libraries installed into:")
print(jni_dir)

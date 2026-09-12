import std/[os, strutils]

let repoRoot =
  currentSourcePath()
    .parentDir()
    .parentDir()

let upstreamDir =
  repoRoot / "vendor" / "termux-app"

let overlayDir =
  repoRoot / "appforge" / "overlay"

let workRoot =
  getHomeDir() / ".cache" / "termux-appforge"

let worktreeDir =
  workRoot / "termux-app"

let nativeOut =
  workRoot / "native"

let sdkRoot =
  workRoot / "android-sdk"

let downloadDir =
  workRoot / "downloads"

let artifactDir =
  repoRoot / "build"

let prefix =
  getEnv("PREFIX")


proc run(command: string) =
  echo "> ", command

  let exitCode =
    execShellCmd(command)

  if exitCode != 0:
    echo ""
    echo "FAILED"
    echo "Exit code: ", exitCode
    quit(1)


proc capture(command: string): string =
  let tempFile =
    workRoot / "capture.txt"

  createDir(workRoot)

  let fullCommand =
    command &
    " > \"" &
    tempFile &
    "\" 2>&1"

  let exitCode =
    execShellCmd(fullCommand)

  if exitCode != 0:
    if fileExists(tempFile):
      echo readFile(tempFile)

    quit(1)

  if not fileExists(tempFile):
    return ""

  result =
    readFile(tempFile).strip()

  removeFile(tempFile)


proc requireCommand(name: string) =
  let path =
    capture("command -v " & name)

  if path.len == 0:
    echo "ERROR: Required command missing: ", name
    quit(1)

  echo name, ": ", path


proc checkEnvironment() =
  echo "== Checking AppForge environment =="

  if prefix.len == 0:
    echo "ERROR: PREFIX environment variable is missing."
    quit(1)

  for command in [
    "git",
    "curl",
    "unzip",
    "sha256sum",
    "clang",
    "clang++",
    "python",
    "java",
    "file",
    "aapt2",
    "aidl",
    "zipalign",
    "apksigner"
  ]:
    requireCommand(command)


proc checkUpstream() =
  echo ""
  echo "== Checking upstream Termux =="

  if not dirExists(upstreamDir):
    echo "ERROR: vendor/termux-app was not found."
    quit(1)

  let status =
    capture(
      "git -C \"" &
      upstreamDir &
      "\" status --porcelain"
    )

  if status.len > 0:
    echo "ERROR: Upstream Termux contains local modifications."
    echo status
    quit(1)

  let commit =
    capture(
      "git -C \"" &
      upstreamDir &
      "\" rev-parse HEAD"
    )

  echo "Upstream clean."
  echo "Termux commit: ", commit


proc createStaging() =
  echo ""
  echo "== Creating staging copy =="

  createDir(workRoot)

  if dirExists(worktreeDir):
    removeDir(worktreeDir)

  run(
    "cp -a \"" &
    upstreamDir &
    "\" \"" &
    worktreeDir &
    "\""
  )

  echo "Staging:"
  echo worktreeDir


proc applyOverlay() =
  echo ""
  echo "== Applying AppForge overlay =="

  if dirExists(overlayDir):
    run(
      "cp -a \"" &
      overlayDir &
      "/.\" \"" &
      worktreeDir &
      "/\""
    )

  echo "Overlay applied."


proc prepareBootstrap() =
  echo ""
  echo "== Preparing official Termux bootstrap =="

  createDir(downloadDir)

  let cached =
    downloadDir / "bootstrap-aarch64.zip"

  let destination =
    worktreeDir /
    "app" /
    "src" /
    "main" /
    "cpp" /
    "bootstrap-aarch64.zip"

  let expectedHash =
    "ea2aeba8819e517db711f8c32369e89e7c52cee73e07930ff91185e1ab93f4f3"

  let url =
    "https://github.com/termux/termux-packages/releases/download/" &
    "bootstrap-2026.02.12-r1%2Bapt.android-7/" &
    "bootstrap-aarch64.zip"

  var validCache = false

  if fileExists(cached):
    let hash =
      capture(
        "sha256sum \"" &
        cached &
        "\" | cut -d' ' -f1"
      )

    validCache =
      hash == expectedHash

  if not validCache:
    if fileExists(cached):
      removeFile(cached)

    run(
      "curl --fail -L \"" &
      url &
      "\" -o \"" &
      cached &
      "\""
    )

  let finalHash =
    capture(
      "sha256sum \"" &
      cached &
      "\" | cut -d' ' -f1"
    )

  if finalHash != expectedHash:
    echo "ERROR: Bootstrap checksum mismatch."
    quit(1)

  copyFile(cached, destination)

  echo "Bootstrap checksum verified."


proc buildNative() =
  echo ""
  echo "== Building Termux native libraries =="

  if dirExists(nativeOut):
    removeDir(nativeOut)

  createDir(nativeOut)

  let termuxC =
    worktreeDir /
    "terminal-emulator" /
    "src" /
    "main" /
    "jni" /
    "termux.c"

  let socketCpp =
    worktreeDir /
    "termux-shared" /
    "src" /
    "main" /
    "cpp" /
    "local-socket.cpp"

  let bootstrapDir =
    worktreeDir /
    "app" /
    "src" /
    "main" /
    "cpp"

  run(
    "clang -shared -fPIC -O2 " &
    "-I\"" & prefix & "/include\" " &
    "\"" & termuxC & "\" " &
    "-o \"" &
    nativeOut / "libtermux.so" &
    "\""
  )

  run(
    "clang++ -shared -fPIC -O2 " &
    "-I\"" & prefix & "/include\" " &
    "\"" & socketCpp & "\" " &
    "-llog " &
    "-o \"" &
    nativeOut / "liblocal-socket.so" &
    "\""
  )

  let oldDir =
    getCurrentDir()

  setCurrentDir(bootstrapDir)

  run(
    "clang -shared -fPIC -O2 " &
    "-I\"" & prefix & "/include\" " &
    "termux-bootstrap.c " &
    "termux-bootstrap-zip.S " &
    "-o \"" &
    nativeOut / "libtermux-bootstrap.so" &
    "\""
  )

  setCurrentDir(oldDir)

  echo "Native build completed."


proc verifyNative() =
  echo ""
  echo "== Verifying native artifacts =="

  for name in [
    "libtermux.so",
    "liblocal-socket.so",
    "libtermux-bootstrap.so"
  ]:
    let path =
      nativeOut / name

    if not fileExists(path):
      echo "ERROR: Missing ", name
      quit(1)

    let info =
      capture(
        "file \"" &
        path &
        "\""
      )

    echo info

    if "AArch64" notin info and
       "arm64" notin info:
      echo "ERROR: Wrong architecture: ", name
      quit(1)

  echo "Native libraries verified."


proc prepareAndroidSdk() =
  echo ""
  echo "== Preparing AppForge Android SDK =="

  let script =
    repoRoot /
    "appforge" /
    "build-adapter" /
    "prepare_android_sdk.sh"

  if not fileExists(script):
    echo "ERROR: Android SDK adapter script is missing."
    quit(1)

  run(
    "bash \"" &
    script &
    "\" \"" &
    sdkRoot &
    "\""
  )


proc prepareGradle() =
  echo ""
  echo "== Preparing Gradle staging =="

  let adapter =
    repoRoot /
    "appforge" /
    "build-adapter" /
    "prepare_gradle.py"

  run(
    "python \"" &
    adapter &
    "\" \"" &
    worktreeDir &
    "\" \"" &
    nativeOut &
    "\""
  )

  writeFile(
    worktreeDir / "local.properties",
    "sdk.dir=" &
    sdkRoot &
    "\n"
  )

  let properties =
    worktreeDir / "gradle.properties"

  var lines: seq[string] = @[]

  for line in readFile(properties).splitLines():
    if not line.startsWith(
      "android.aapt2FromMavenOverride="
    ):
      lines.add(line)

  lines.add(
    "android.aapt2FromMavenOverride=" &
    prefix &
    "/bin/aapt2"
  )

  writeFile(
    properties,
    lines.join("\n") & "\n"
  )

  run(
    "chmod +x \"" &
    worktreeDir /
    "gradlew" &
    "\""
  )

  echo "Gradle staging ready."


proc buildApk() =
  echo ""
  echo "== Building ARM64 APK =="

  let oldDir =
    getCurrentDir()

  setCurrentDir(worktreeDir)

  run(
    "./gradlew :app:assembleDebug --console=plain"
  )

  setCurrentDir(oldDir)


proc verifyApk() =
  echo ""
  echo "== Verifying APK =="

  let apk =
    worktreeDir /
    "app" /
    "build" /
    "outputs" /
    "apk" /
    "debug" /
    "termux-app_apt-android-7-debug_arm64-v8a.apk"

  if not fileExists(apk):
    echo "ERROR: ARM64 APK was not generated."
    quit(1)

  for lib in [
    "lib/arm64-v8a/libtermux.so",
    "lib/arm64-v8a/liblocal-socket.so",
    "lib/arm64-v8a/libtermux-bootstrap.so"
  ]:
    run(
      "unzip -l \"" &
      apk &
      "\" | grep -F \"" &
      lib &
      "\" > /dev/null"
    )

  run(
    "apksigner verify --verbose \"" &
    apk &
    "\""
  )

  createDir(artifactDir)

  let output =
    artifactDir /
    "termux-appforge-debug-arm64-v8a.apk"

  copyFile(apk, output)

  echo ""
  echo "APK verified:"
  echo output


proc verifyUpstreamStillClean() =
  echo ""
  echo "== Re-checking upstream =="

  let status =
    capture(
      "git -C \"" &
      upstreamDir &
      "\" status --porcelain"
    )

  if status.len > 0:
    echo "ERROR: Upstream Termux was modified."
    quit(1)

  echo "Original upstream remains unchanged."


proc main() =
  echo "===================================="
  echo "        Termux AppForge Builder"
  echo "===================================="
  echo ""

  checkEnvironment()
  checkUpstream()

  createStaging()
  applyOverlay()

  prepareBootstrap()

  buildNative()
  verifyNative()

  prepareAndroidSdk()
  prepareGradle()

  buildApk()
  verifyApk()

  verifyUpstreamStillClean()

  echo ""
  echo "===================================="
  echo "      APPFORGE BUILD SUCCESSFUL"
  echo "===================================="
  echo ""
  echo "Output:"
  echo artifactDir / "termux-appforge-debug-arm64-v8a.apk"


main()

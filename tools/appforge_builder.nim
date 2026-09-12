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

let prefix =
  getEnv("PREFIX")

proc run(command: string) =
  echo "> ", command

  let exitCode = execShellCmd(command)

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
    command & " > \"" & tempFile & "\" 2>&1"

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

proc checkUpstream() =
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
    echo ""
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

proc createWorktree() =
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

  echo "Staging copy created:"
  echo worktreeDir

proc applyOverlay() =
  echo ""
  echo "== Applying AppForge overlay =="

  if not dirExists(overlayDir):
    echo "No overlay directory found."
    return

  run(
    "cp -a \"" &
    overlayDir &
    "/.\" \"" &
    worktreeDir &
    "/\""
  )

  echo "Overlay applied."

proc downloadBootstrap() =
  echo ""
  echo "== Preparing official bootstrap =="

  let cppDir =
    worktreeDir / "app" / "src" / "main" / "cpp"

  let bootstrap =
    cppDir / "bootstrap-aarch64.zip"

  let expectedHash =
    "ea2aeba8819e517db711f8c32369e89e7c52cee73e07930ff91185e1ab93f4f3"

  let url =
    "https://github.com/termux/termux-packages/releases/download/" &
    "bootstrap-2026.02.12-r1%2Bapt.android-7/" &
    "bootstrap-aarch64.zip"

  if not fileExists(bootstrap):
    run(
      "curl -L \"" &
      url &
      "\" -o \"" &
      bootstrap &
      "\""
    )

  let actualHash =
    capture(
      "sha256sum \"" &
      bootstrap &
      "\" | cut -d' ' -f1"
    )

  if actualHash != expectedHash:
    echo "ERROR: Bootstrap SHA-256 mismatch."
    echo "Expected: ", expectedHash
    echo "Actual:   ", actualHash
    quit(1)

  echo "Bootstrap checksum verified."

proc buildNative() =
  echo ""
  echo "== Building Termux native libraries =="

  if dirExists(nativeOut):
    removeDir(nativeOut)

  createDir(nativeOut)

  let terminalC =
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
    "clang " &
    "-shared -fPIC -O2 " &
    "-I\"" & prefix & "/include\" " &
    "\"" & terminalC & "\" " &
    "-o \"" & nativeOut / "libtermux.so" & "\""
  )

  run(
    "clang++ " &
    "-shared -fPIC -O2 " &
    "-I\"" & prefix & "/include\" " &
    "\"" & socketCpp & "\" " &
    "-llog " &
    "-o \"" & nativeOut / "liblocal-socket.so" & "\""
  )

  let oldDir = getCurrentDir()

  setCurrentDir(bootstrapDir)

  run(
    "clang " &
    "-shared -fPIC -O2 " &
    "-I\"" & prefix & "/include\" " &
    "termux-bootstrap.c " &
    "termux-bootstrap-zip.S " &
    "-o \"" & nativeOut / "libtermux-bootstrap.so" & "\""
  )

  setCurrentDir(oldDir)

  echo "Native build completed."

proc verifyNative() =
  echo ""
  echo "== Verifying native artifacts =="

  let files = [
    "libtermux.so",
    "liblocal-socket.so",
    "libtermux-bootstrap.so"
  ]

  for name in files:
    let path =
      nativeOut / name

    if not fileExists(path):
      echo "ERROR: Missing ", name
      quit(1)

    let description =
      capture(
        "file \"" &
        path &
        "\""
      )

    echo name, ":"
    echo description

    if "AArch64" notin description and
       "arm64" notin description:
      echo "ERROR: Wrong architecture."
      quit(1)

  echo "All native libraries verified."

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
    echo "ERROR: Upstream was modified."
    quit(1)

  echo "Original Termux source remains unchanged."

proc main() =
  echo "================================="
  echo "       Termux AppForge Builder"
  echo "================================="
  echo ""

  checkUpstream()
  createWorktree()
  applyOverlay()
  downloadBootstrap()
  buildNative()
  verifyNative()
  verifyUpstreamStillClean()

  echo ""
  echo "================================="
  echo "NATIVE BUILD PIPELINE SUCCESSFUL"
  echo "================================="
  echo ""
  echo "Staging:"
  echo worktreeDir
  echo ""
  echo "Native output:"
  echo nativeOut
  echo ""
  echo "Next stage: integrate native output into APK build."

main()

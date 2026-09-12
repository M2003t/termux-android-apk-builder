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
    getTempDir() / "appforge_capture.txt"

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
    echo ""
    echo status
    echo ""
    echo "AppForge refuses to build from a modified upstream tree."
    quit(1)

  let commit =
    capture(
      "git -C \"" &
      upstreamDir &
      "\" rev-parse HEAD"
    )

  echo ""
  echo "Upstream clean."
  echo "Termux commit: ", commit

proc createWorktree() =
  echo ""
  echo "== Creating AppForge worktree =="

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

  echo ""
  echo "Worktree created:"
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

  echo ""
  echo "Overlay applied."

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
  verifyUpstreamStillClean()

  echo ""
  echo "================================="
  echo "WORKTREE PREPARATION SUCCESSFUL"
  echo "================================="
  echo ""
  echo "Upstream:"
  echo upstreamDir
  echo ""
  echo "Working copy:"
  echo worktreeDir
  echo ""
  echo "Next stage: build Android APK."

main()

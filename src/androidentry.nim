import app

proc NimMain() {.importc.}

proc main*(argc: cint, argv: ptr cstring): cint {.exportc: "main", cdecl.} =
  NimMain()
  return 0

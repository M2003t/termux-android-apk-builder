{.compile: "termux_bridge.c".}

proc termuxRunTestNative(): cint
  {.importc: "termux_run_test".}

proc runTermuxTest*(): bool =
  result = termuxRunTestNative() == 0

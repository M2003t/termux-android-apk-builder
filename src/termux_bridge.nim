{.compile: "termux_bridge.c".}

proc termuxPermissionStatusNative(): cint
  {.importc: "termux_permission_status".}

proc termuxRequestPermissionNative(): cint
  {.importc: "termux_request_permission".}

proc termuxRunTestNative(): cint
  {.importc: "termux_run_test".}

proc hasTermuxPermission*(): bool =
  termuxPermissionStatusNative() == 1

proc requestTermuxPermission*(): bool =
  termuxRequestPermissionNative() == 0

proc runTermuxTest*(): bool =
  termuxRunTestNative() == 0

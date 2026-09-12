{.compile: "termux_bridge.c".}

proc termuxPermissionStatusNative(): cint
  {.importc: "termux_permission_status".}

proc termuxRequestPermissionNative(): cint
  {.importc: "termux_request_permission".}

proc termuxRunTestNative(): cint
  {.importc: "termux_run_test".}

proc termuxOpenAppSettingsNative(): cint
  {.importc: "termux_open_app_settings".}

proc termuxPermissionStatus*(): int =
  int(termuxPermissionStatusNative())

proc requestTermuxPermission*(): int =
  int(termuxRequestPermissionNative())

proc runTermuxTest*(): int =
  int(termuxRunTestNative())

proc openAppSettings*(): int =
  int(termuxOpenAppSettingsNative())

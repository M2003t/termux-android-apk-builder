{.compile: "termux_bridge.c".}

proc termuxPackageStatusNative(): cint
  {.importc: "termux_package_status".}

proc termuxPermissionDefinitionStatusNative(): cint
  {.importc: "termux_permission_definition_status".}

proc termuxPermissionStatusNative(): cint
  {.importc: "termux_permission_status".}

proc termuxRequestPermissionNative(): cint
  {.importc: "termux_request_permission".}

proc termuxOpenAppSettingsNative(): cint
  {.importc: "termux_open_app_settings".}

proc termuxRunTestNative(): cint
  {.importc: "termux_run_test".}

proc termuxPackageStatus*(): int =
  int(termuxPackageStatusNative())

proc termuxPermissionDefinitionStatus*(): int =
  int(termuxPermissionDefinitionStatusNative())

proc termuxPermissionStatus*(): int =
  int(termuxPermissionStatusNative())

proc requestTermuxPermission*(): int =
  int(termuxRequestPermissionNative())

proc openAppSettings*(): int =
  int(termuxOpenAppSettingsNative())

proc runTermuxTest*(): int =
  int(termuxRunTestNative())

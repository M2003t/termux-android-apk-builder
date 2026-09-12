import raylib
import termux_bridge

const buildId {.strdefine.} = "development"

initWindow(800, 450, "Termux AppForge")

var packageStatus = 0
var definitionStatus = 0
var permissionStatus = 0

var requestResult = -999
var settingsResult = -999
var commandResult = -999

let requestButton =
  Rectangle(x: 40, y: 285, width: 220, height: 50)

let settingsButton =
  Rectangle(x: 290, y: 285, width: 220, height: 50)

let commandButton =
  Rectangle(x: 540, y: 285, width: 220, height: 50)

while not windowShouldClose():

  packageStatus =
    termuxPackageStatus()

  definitionStatus =
    termuxPermissionDefinitionStatus()

  permissionStatus =
    termuxPermissionStatus()

  let mouse = getMousePosition()

  let requestHover =
    checkCollisionPointRec(mouse, requestButton)

  let settingsHover =
    checkCollisionPointRec(mouse, settingsButton)

  let commandHover =
    checkCollisionPointRec(mouse, commandButton)

  if isMouseButtonPressed(MouseButton.Left):

    if requestHover:
      requestResult =
        requestTermuxPermission()

    if settingsHover:
      settingsResult =
        openAppSettings()

    if commandHover:
      commandResult =
        runTermuxTest()

  beginDrawing()
  clearBackground(RAYWHITE)

  drawText(
    "Termux AppForge Diagnostics",
    30, 25, 28, BLACK
  )

  drawText(
    "Build ID: " & buildId,
    30, 70, 17, GRAY
  )

  drawText(
    "Termux package visible:       " &
    $packageStatus,
    30, 115, 19, BLACK
  )

  drawText(
    "RUN_COMMAND defined:          " &
    $definitionStatus,
    30, 145, 19, BLACK
  )

  drawText(
    "RUN_COMMAND granted:          " &
    $permissionStatus,
    30, 175, 19, BLACK
  )

  drawText(
    "Permission request result:    " &
    $requestResult,
    30, 205, 19, DARKGRAY
  )

  drawText(
    "Open settings result:         " &
    $settingsResult,
    30, 235, 19, DARKGRAY
  )

  drawText(
    "Command result:               " &
    $commandResult,
    430, 235, 19, DARKGRAY
  )

  drawRectangle(
    int32(requestButton.x),
    int32(requestButton.y),
    int32(requestButton.width),
    int32(requestButton.height),
    if requestHover: GRAY else: LIGHTGRAY
  )

  drawText(
    "Request Permission",
    55, 301, 18, BLACK
  )

  drawRectangle(
    int32(settingsButton.x),
    int32(settingsButton.y),
    int32(settingsButton.width),
    int32(settingsButton.height),
    if settingsHover: GRAY else: LIGHTGRAY
  )

  drawText(
    "Open App Settings",
    310, 301, 18, BLACK
  )

  drawRectangle(
    int32(commandButton.x),
    int32(commandButton.y),
    int32(commandButton.width),
    int32(commandButton.height),
    if commandHover: GRAY else: LIGHTGRAY
  )

  drawText(
    "Test RUN_COMMAND",
    560, 301, 18, BLACK
  )

  drawText(
    "1 = yes/granted   0 = no/denied   negative = diagnostic error",
    30, 370, 17, GRAY
  )

  endDrawing()

closeWindow()

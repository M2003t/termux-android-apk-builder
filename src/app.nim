import raylib
import termux_bridge

const buildId {.strdefine.} = "development"

initWindow(800, 450, "Termux AppForge")

var permissionStatus = termuxPermissionStatus()
var requestResult = -999
var commandResult = -999
var commandTested = false

let requestButton = Rectangle(
  x: 40,
  y: 245,
  width: 330,
  height: 55
)

let settingsButton = Rectangle(
  x: 40,
  y: 320,
  width: 330,
  height: 55
)

while not windowShouldClose():

  permissionStatus = termuxPermissionStatus()

  if permissionStatus == 1 and not commandTested:
    commandResult = runTermuxTest()
    commandTested = true

  let mouse = getMousePosition()

  let requestHover =
    checkCollisionPointRec(mouse, requestButton)

  let settingsHover =
    checkCollisionPointRec(mouse, settingsButton)

  if isMouseButtonPressed(MouseButton.Left):

    if requestHover and permissionStatus == 0:
      requestResult = requestTermuxPermission()

    if settingsHover and permissionStatus == 0:
      discard openAppSettings()

  beginDrawing()
  clearBackground(RAYWHITE)

  drawText(
    "Termux AppForge",
    40, 40, 32, BLACK
  )

  drawText(
    "Native Android development on your phone.",
    40, 100, 20, DARKGRAY
  )

  drawText(
    "Build ID: " & buildId,
    40, 155, 18, GRAY
  )

  if permissionStatus == 1:

    if commandResult == 0:
      drawText(
        "Termux Connected",
        40, 210, 22, DARKGREEN
      )
    else:
      drawText(
        "Termux command error: " & $commandResult,
        40, 210, 20, RED
      )

  elif permissionStatus == 0:

    drawText(
      "Termux permission required",
      40, 205, 20, ORANGE
    )

    drawRectangle(
      int32(requestButton.x),
      int32(requestButton.y),
      int32(requestButton.width),
      int32(requestButton.height),
      if requestHover: GRAY else: LIGHTGRAY
    )

    drawText(
      "Request Termux Permission",
      60, 262, 20, BLACK
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
      60, 337, 20, BLACK
    )

    if requestResult != -999:
      drawText(
        "Request result: " & $requestResult,
        400, 262, 18, DARKGRAY
      )

  else:

    drawText(
      "Permission check error: " & $permissionStatus,
      40, 210, 20, RED
    )

  endDrawing()

closeWindow()

import raylib
import termux_bridge

const buildId {.strdefine.} = "development"

initWindow(800, 450, "Termux AppForge")

var statusText = "Checking Termux permission..."
var statusColor = DARKGRAY

if hasTermuxPermission():
  if runTermuxTest():
    statusText = "Termux connected"
    statusColor = DARKGREEN
  else:
    statusText = "Termux command failed"
    statusColor = RED
else:
  discard requestTermuxPermission()
  statusText = "Termux permission requested"
  statusColor = ORANGE

while not windowShouldClose():
  beginDrawing()
  clearBackground(RAYWHITE)

  drawText("Termux AppForge", 40, 40, 32, BLACK)

  drawText(
    "Native Android development on your phone.",
    40, 100, 20, DARKGRAY
  )

  drawText(
    "Build ID: " & buildId,
    40, 160, 18, GRAY
  )

  drawText(
    statusText,
    40, 210, 20, statusColor
  )

  endDrawing()

closeWindow()

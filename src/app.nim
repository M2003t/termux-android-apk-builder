import raylib
import termux_bridge

const buildId {.strdefine.} = "development"

initWindow(800, 450, "Termux AppForge")

let termuxConnected = runTermuxTest()

while not windowShouldClose():
  beginDrawing()
  clearBackground(RAYWHITE)

  drawText(
    "Termux AppForge",
    40,
    40,
    32,
    BLACK
  )

  drawText(
    "Native Android development on your phone.",
    40,
    100,
    20,
    DARKGRAY
  )

  drawText(
    "Build ID: " & buildId,
    40,
    160,
    18,
    GRAY
  )

  if termuxConnected:
    drawText(
      "Termux command sent successfully",
      40,
      210,
      20,
      DARKGREEN
    )
  else:
    drawText(
      "Termux connection failed",
      40,
      210,
      20,
      RED
    )

  endDrawing()

closeWindow()

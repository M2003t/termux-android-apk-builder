import raylib

const buildId {.strdefine.} = "development"

initWindow(800, 450, "Termux AppForge")

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

  endDrawing()

closeWindow()

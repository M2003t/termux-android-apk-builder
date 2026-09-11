import raylib

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

  endDrawing()

closeWindow()

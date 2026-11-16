-- Quake mode: Cmd+1 (Ctrl+1 with swapped modifiers) shows Alacritty on the top half of the current screen,
-- or minimizes it when focused, since Hammerspoon takes the key before Alacritty sees it
hs.autoLaunch(true)

hs.hotkey.bind({ "cmd" }, "1", function()
  local app = hs.application.get("Alacritty")
  if app and app:isFrontmost() and app:focusedWindow() then
    return app:focusedWindow():minimize()
  end

  local screen = hs.mouse.getCurrentScreen():frame()
  hs.application.launchOrFocus("Alacritty")
  hs.timer.waitUntil(function()
    app = hs.application.get("Alacritty")
    return app and app:mainWindow()
  end, function()
    app:mainWindow():unminimize():focus():setFrame({ x = screen.x, y = screen.y, w = screen.w, h = screen.h / 2 }, 0)
  end, 0.05)
end)

#Requires AutoHotkey v2.0
#SingleInstance Force

; Quake mode: Ctrl+1 shows Alacritty on the top half of the primary screen, inside Alacritty its own Ctrl+1 minimizes
#HotIf !WinActive("ahk_exe alacritty.exe")
^1:: {
  if !WinExist("ahk_exe alacritty.exe") {
    Run "alacritty.exe", EnvGet("USERPROFILE")
    WinWait "ahk_exe alacritty.exe"
  }
  WinRestore
  WinActivate
  MonitorGetWorkArea MonitorGetPrimary(), &left, &top, &right, &bottom
  WinMove left, top, right - left, (bottom - top) // 2
}

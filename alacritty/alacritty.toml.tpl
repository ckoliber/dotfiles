[window]
level = "AlwaysOnTop"
position = { x = 0, y = 0 }
dimensions = { columns = 0, lines = 30 }
decorations = "None"
opacity = 0.8

[selection]
save_to_clipboard = true

[keyboard]
bindings = [
#if OSX
  { key = "A", mods = "Command", chars = "\u0001" },       # Ctrl+A  line start
  { key = "B", mods = "Command", chars = "\u0002" },       # Ctrl+B  back char
  { key = "C", mods = "Command", chars = "\u0003" },       # Ctrl+C  SIGINT
  { key = "D", mods = "Command", chars = "\u0004" },       # Ctrl+D  EOF
  { key = "E", mods = "Command", chars = "\u0005" },       # Ctrl+E  line end
  { key = "F", mods = "Command", chars = "\u0006" },       # Ctrl+F  forward char
  { key = "K", mods = "Command", chars = "\u000B" },       # Ctrl+K  kill line forward
  { key = "N", mods = "Command", chars = "\u000E" },       # Ctrl+N  next
  { key = "O", mods = "Command", chars = "\u000F" },       # Ctrl+O  accept line
  { key = "P", mods = "Command", chars = "\u0010" },       # Ctrl+P  previous
  { key = "Q", mods = "Command", chars = "\u0011" },       # Ctrl+Q  XON
  { key = "R", mods = "Command", chars = "\u0012" },       # Ctrl+R  reverse search
  { key = "S", mods = "Command", chars = "\u0013" },       # Ctrl+S  forward search
  { key = "T", mods = "Command", chars = "\u0014" },       # Ctrl+T  transpose chars
  { key = "U", mods = "Command", chars = "\u0015" },       # Ctrl+U  kill line back
  { key = "V", mods = "Command", chars = "\u0016" },       # Ctrl+V  quoted insert
  { key = "W", mods = "Command", chars = "\u0017" },       # Ctrl+W  delete word back
  { key = "X", mods = "Command", chars = "\u0018" },       # Ctrl+X  cut
  { key = "Y", mods = "Command", chars = "\u0019" },       # Ctrl+Y  yank
  { key = "Z", mods = "Command", chars = "\u001A" },       # Ctrl+Z  SIGTSTP
  { key = "C", mods = "Command|Shift", action = "Copy" },  # Copy
  { key = "V", mods = "Command|Shift", action = "Paste" }, # Paste
#else
  { key = "C", mods = "Control|Shift", action = "Copy" },  # Copy
  { key = "V", mods = "Control|Shift", action = "Paste" }, # Paste
#end
]

#if WINDOWS
[general]
working_directory = '$(cygpath -w "$HOME")'
#end

[terminal.shell]
#if WINDOWS
program = "C:\\\\Program Files\\\\Git\\\\bin\\\\bash.exe"
#elif LINUX
program = "/usr/bin/bash"
#elif OSX
program = "/opt/homebrew/bin/bash"
#end
args = ["--login"]

[font]
normal = { family = "MesloLGM Nerd Font" }
size = 14

# Colors (Hyper)

# Default colors
[colors.primary]
background = '#000000'
foreground = '#ffffff'

[colors.cursor]
text = '#F81CE5'
cursor = '#ffffff'

# Normal colors
[colors.normal]
black = '#000000'
red = '#fe0100'
green = '#33ff00'
yellow = '#feff00'
blue = '#0066ff'
magenta = '#cc00ff'
cyan = '#00ffff'
white = '#d0d0d0'

# Bright colors
[colors.bright]
black = '#808080'
red = '#fe0100'
green = '#33ff00'
yellow = '#feff00'
blue = '#0066ff'
magenta = '#cc00ff'
cyan = '#00ffff'
white = '#FFFFFF'

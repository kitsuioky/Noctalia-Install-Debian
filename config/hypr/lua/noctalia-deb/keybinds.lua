-- keybinds.lua — atalhos de teclado (gerenciado pelo Noctalia-install-deb)
-- Os atalhos do mouse estão em mouse.lua.
local mod = "SUPER"
local ipc = "@SHELL_BIN@ msg "
local function run(cmd) return hl.dsp.exec_cmd(cmd) end

-- Programas
hl.bind(mod .. " + Return", run("alacritty"))
hl.bind(mod .. " + E", run("nautilus"))
hl.bind(mod .. " + B", run("brave-origin"))
hl.bind(mod .. " + Space", run(ipc .. "panel-toggle launcher"))
hl.bind(mod .. " + D", run(ipc .. "panel-toggle launcher"))
hl.bind(mod .. " + S", run(ipc .. "panel-toggle control-center"))
hl.bind(mod .. " + comma", run(ipc .. "settings-toggle"))
hl.bind(mod .. " + X", run(ipc .. "panel-toggle session"))
hl.bind(mod .. " + L", run("sh -c '@SHELL_BIN@ msg session lock || @SHELL_BIN@ msg screen-lock'"))

-- Janelas
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
for key, dir in pairs({ left = "left", right = "right", up = "up", down = "down" }) do
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end
hl.bind("ALT + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({}))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Sair do Hyprland
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())

-- Capturas de tela
hl.bind("Print", run(ipc .. "screenshot-region"))
hl.bind("SHIFT + Print", run("sh -c 'grim - | wl-copy'"))

-- Volume, brilho (teclas do teclado/notebook)
hl.bind("XF86AudioRaiseVolume", run(ipc .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", run(ipc .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", run(ipc .. "volume-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", run(ipc .. "brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", run(ipc .. "brightness-down"), { locked = true, repeating = true })

-- Áreas de trabalho
for i = 1, 9 do
  hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

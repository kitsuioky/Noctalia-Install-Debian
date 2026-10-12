-- windowrules.lua — janelas utilitárias abrem flutuando (fáceis de mover/redimensionar com o mouse)
local floating = {
  "^(pavucontrol|org.pulseaudio.pavucontrol)$",
  "^(nm-connection-editor|blueman-manager|.blueman-manager-wrapped)$",
  "^(org.gnome.Calculator|org.gnome.SystemMonitor|org.gnome.DiskUtility)$",
  "^(xdg-desktop-portal-gtk|org.freedesktop.impl.portal.desktop.gtk)$",
}
for i, pattern in ipairs(floating) do
  hl.window_rule({ name = "noctalia-deb-float-" .. i, match = { class = pattern }, float = true })
end

hl.window_rule({
  name = "noctalia-deb-file-dialogs",
  match = { title = "^(Abrir arquivo|Salvar como|Open File|Save As|Open Folder|Select Folder)$" },
  float = true,
})

-- Janela de configurações do Noctalia (recomendado pela doc)
hl.window_rule({
  name = "noctalia-deb-settings",
  match = { class = "@SHELL_APPID@" },
  float = true,
  size = { 1080, 920 },
})

-- Blur nas superfícies do Noctalia (recomendado pela doc)
hl.layer_rule({
  name = "noctalia",
  match = { namespace = "^@SHELL_BIN@-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})

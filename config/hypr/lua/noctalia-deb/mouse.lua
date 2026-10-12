-- mouse.lua — suporte a mouse nas janelas (gerenciado pelo Noctalia-install-deb)
--   Super + arrastar com botão ESQUERDO = mover a janela
--   Super + arrastar com botão DIREITO  = redimensionar a janela
--   Arrastar a BORDA da janela          = redimensionar
--   Super + roda do mouse               = trocar de área de trabalho
hl.config({
  general = {
    resize_on_border = true,
    extend_border_grab_area = 15,
    hover_icon_on_border = true,
  },
  input = {
    follow_mouse = 1,
    float_switch_override_focus = 2,
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      clickfinger_behavior = true,
      disable_while_typing = true,
    },
  },
})

local mod = "SUPER"
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- look.lua — visual (valores recomendados pela doc do Noctalia) e teclado
hl.config({
  input = { kb_layout = "@KB_LAYOUT@" },
  general = { gaps_in = 5, gaps_out = 10, border_size = 2 },
  decoration = {
    rounding = 20,
    rounding_power = 2,
    shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
    blur = { enabled = true, size = 3, passes = 2, vibrancy = 0.1696 },
  },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})

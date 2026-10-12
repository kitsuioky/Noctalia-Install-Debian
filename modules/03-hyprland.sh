#!/usr/bin/env bash
# 03-hyprland.sh — Hyprland e componentes de sessão.
# (O Noctalia v5 já traz o próprio agente de senha/polkit, então não instalamos outro.)

module_main() {
  step "03 — Hyprland"
  pkg_available hyprland || die "O pacote 'hyprland' não está disponível no Debian testing agora. Veja docs/TROUBLESHOOTING.md."

  apt_install hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xwayland \
    qt6-wayland wl-clipboard grim slurp cliphist brightnessctl \
    adwaita-icon-theme libglib2.0-bin
  apt_install_optional swappy
  # Utilitários gráficos do Hyprland (diálogos/avisos; substitui o antigo hyprland-qtutils)
  apt_install_optional hyprland-guiutils

  info "Hyprland $(hyprland_version) -> config em modo: $(hyprland_config_mode)"
  ok "Hyprland instalado"
}

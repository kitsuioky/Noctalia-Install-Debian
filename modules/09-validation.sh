#!/usr/bin/env bash
# 09-validation.sh — confere se tudo foi instalado e configurado.

module_main() {
  step "09 — Validação"
  CHECK_FAIL=0; CHECK_WARN=0

  for p in hyprland nautilus alacritty gnome-software network-manager bluez pipewire wireplumber; do check_pkg "$p"; done
  if pkg_installed hyprland-guiutils; then check_ok "pacote: hyprland-guiutils"; else check_warn "hyprland-guiutils não instalado (opcional)"; fi
  if [[ -x /usr/local/bin/kyo || -x /usr/local/bin/noctalia ]]; then check_ok "shell compilado do fork em /usr/local/bin"
  elif pkg_installed noctalia; then check_ok "shell do pacote oficial (apt): noctalia"
  else check_fail "shell: nem o compilado nem o pacote 'noctalia' foram encontrados"; fi
  if [[ $WITH_PLYMOUTH == 1 ]]; then
    if command -v plymouth-set-default-theme >/dev/null 2>&1; then check_ok "Plymouth: tema atual $(plymouth-set-default-theme 2>/dev/null)"; else check_warn "Plymouth não instalado"; fi
  fi
  if pkg_installed brave-origin; then check_ok "pacote: brave-origin"; else check_warn "brave-origin não instalado (opcional)"; fi
  if pkg_installed greetd; then check_ok "pacote: greetd"; else check_warn "greetd não instalado (login gráfico desativado)"; fi

  check_cmd Hyprland
  detect_shell_binary
  check_cmd "$SHELL_BIN"

  local h="$TARGET_HOME/.config/hypr" mode main ext marker
  mode="$(hyprland_config_mode)"
  if [[ $mode == lua ]]; then main="$h/hyprland.lua"; ext=lua; marker='-- >>> noctalia-install-deb >>>'
  else main="$h/hyprland.conf"; ext=conf; marker='# >>> noctalia-install-deb >>>'; fi

  check_file "$main"
  for f in env autostart look mouse keybinds windowrules; do check_file "$h/noctalia-deb/$f.$ext"; done
  if grep -qF -- "$marker" "$main" 2>/dev/null; then check_ok "$(basename "$main") carrega as configs do instalador"
  else check_fail "$(basename "$main") não carrega as configs do instalador"; fi

  if systemctl is-enabled NetworkManager.service >/dev/null 2>&1; then check_ok "NetworkManager habilitado"; else check_fail "NetworkManager desabilitado"; fi
  if systemctl is-enabled bluetooth.service >/dev/null 2>&1; then check_ok "Bluetooth habilitado"; else check_warn "Bluetooth desabilitado"; fi
  if pkg_installed greetd; then
    if systemctl is-enabled greetd.service >/dev/null 2>&1; then check_ok "greetd habilitado"; else check_warn "greetd instalado mas não habilitado"; fi
    check_file /etc/greetd/config.toml
  fi
  check_file /usr/local/sbin/noctalia-recover

  # Teste de sintaxe do Hyprland (best-effort: pode falhar fora de uma sessão gráfica)
  if command -v Hyprland >/dev/null 2>&1; then
    if as_user Hyprland --verify-config -c "$main" >/dev/null 2>&1; then
      check_ok "$(basename "$main") passou na verificação do Hyprland"
    else
      check_warn "não consegui verificar o $(basename "$main") agora (normal fora da sessão gráfica). Teste depois: Hyprland --verify-config -c $main"
    fi
  fi

  echo
  if (( CHECK_FAIL > 0 )); then
    err "Validação: $CHECK_FAIL falha(s), $CHECK_WARN aviso(s). Veja o log e docs/TROUBLESHOOTING.md."
    exit 1
  fi
  ok "Validação: tudo certo ($CHECK_WARN aviso(s))"
}

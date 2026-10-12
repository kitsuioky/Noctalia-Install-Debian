#!/usr/bin/env bash
# 07-config.sh — configs do Hyprland (atalhos, mouse, ambiente), sessão e login gráfico (greetd).
#
# Hyprland >= 0.55 usa config em Lua (~/.config/hypr/hyprland.lua).
# Versões antigas usam hyprlang (~/.config/hypr/hyprland.conf). O instalador detecta sozinho.

# Cria o arquivo principal se não existir; se existir, só acrescenta o bloco do instalador (com backup).
ensure_main_config() { # main-file block begin-marker owner [first-line]
  local main=$1 block=$2 begin=$3 owner=$4 first=${5:-}
  if [[ ! -e $main ]]; then
    { [[ -n $first ]] && printf '%s\n\n' "$first"; printf '%s\n' "$block"; } | deploy_stdin "$main" "$owner"
  elif ! grep -qF -- "$begin" "$main"; then
    backup_path "$main"
    printf '\n%s\n' "$block" >>"$main"
    chown "$owner" "$main"
    ok "bloco do Noctalia-install-deb acrescentado ao seu $(basename "$main") (backup feito)"
  else
    info "$(basename "$main") já tem o bloco do instalador — mantido"
  fi
}

deploy_hypr_config() {
  local base="$ROOT_DIR/config/hypr" dst="$TARGET_HOME/.config/hypr" owner="$TARGET_USER:$TARGET_GROUP"
  local mode f rules
  mode="$(hyprland_config_mode)"
  info "Hyprland $(hyprland_version) -> modo de config: $mode"

  if [[ $mode == lua ]]; then
    for f in env autostart look mouse keybinds windowrules; do
      deploy_file "$base/lua/noctalia-deb/$f.lua" "$dst/noctalia-deb/$f.lua" "$owner"
    done
    ensure_main_config "$dst/hyprland.lua" "$(cat "$base/lua/sources.block")" \
      '-- >>> noctalia-install-deb >>>' "$owner"
  else
    for f in env autostart look mouse keybinds; do
      deploy_file "$base/conf/noctalia-deb/$f.conf" "$dst/noctalia-deb/$f.conf" "$owner"
    done
    # A sintaxe das regras de janela mudou no Hyprland 0.53
    if dpkg --compare-versions "$(hyprland_version)" ge 0.53; then rules=windowrules-new.conf; else rules=windowrules-old.conf; fi
    deploy_file "$base/conf/noctalia-deb/$rules" "$dst/noctalia-deb/windowrules.conf" "$owner"
    ensure_main_config "$dst/hyprland.conf" "$(cat "$base/conf/sources.block")" \
      '# >>> noctalia-install-deb >>>' "$owner" 'monitor = ,preferred,auto,1'
  fi
}

write_greetd_config() { # command
  local gu="_greetd"
  getent passwd "$gu" >/dev/null || gu="greeter"
  deploy_stdin /etc/greetd/config.toml root:root 0644 <<EOF
# Gerenciado por Noctalia-install-deb
[terminal]
vt = 1

[default_session]
command = "$1"
user = "$gu"
EOF
}

setup_greetd() {
  local pkg="" cmd="" session_cmd

  # 1) Greeter oficial do Noctalia (se o pacote configurar o greetd sozinho)
  if [[ $GREETER == noctalia ]]; then
    if pkg_available noctalia-greeter; then
      apt_install greetd noctalia-greeter
      if grep -rqs 'noctalia-greeter' /etc/greetd/ 2>/dev/null; then
        systemctl enable --force greetd.service
        ok "Login gráfico (greetd + noctalia-greeter) ativado — começa no próximo boot"
        return 0
      fi
      warn "noctalia-greeter instalado, mas o greetd não ficou apontando para ele — usando tuigreet."
    else
      warn "noctalia-greeter indisponível agora — usando tuigreet."
    fi
    GREETER=tuigreet
  fi

  # 2) tuigreet (texto) ou gtkgreet
  if [[ $GREETER == tuigreet ]]; then
    if pkg_available tuigreet; then
      apt_install greetd tuigreet; pkg=tuigreet
      cmd="tuigreet --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions"
    elif pkg_available gtkgreet && pkg_available cage; then
      warn "tuigreet indisponível — usando gtkgreet"; GREETER=gtkgreet
    fi
  fi
  if [[ $GREETER == gtkgreet && -z $pkg ]] && pkg_available gtkgreet && pkg_available cage; then
    apt_install greetd gtkgreet cage; pkg=gtkgreet
    session_cmd="$(command -v start-hyprland || command -v Hyprland)"
    printf '%s\n' "$session_cmd" | deploy_stdin /etc/greetd/environments
    cmd="cage -s -- gtkgreet"
  fi
  if [[ -z $pkg ]]; then
    warn "Nenhum greeter disponível. O login gráfico NÃO foi ativado; você continua entrando pela TTY."
    warn "Para abrir o Hyprland pela TTY: start-hyprland   (ou: Hyprland)"
    return 0
  fi

  write_greetd_config "$cmd"

  # Garante a sessão Wayland do Hyprland
  if [[ ! -e /usr/share/wayland-sessions/hyprland.desktop ]]; then
    deploy_stdin /usr/share/wayland-sessions/hyprland.desktop <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland + Noctalia
Exec=Hyprland
Type=Application
EOF
  fi

  systemctl enable --force greetd.service
  ok "Login gráfico (greetd + $pkg) ativado — começa no próximo boot"
}

install_recovery_tool() {
  deploy_stdin /usr/local/sbin/noctalia-recover root:root 0755 <<'EOF'
#!/usr/bin/env bash
# Volta para o login em texto (TTY). Use se o login gráfico travar.
set -e
[[ $EUID -eq 0 ]] || { echo "Rode com sudo: sudo noctalia-recover"; exit 1; }
systemctl disable greetd.service || true
systemctl enable getty@tty1.service || true
echo "Pronto: o login gráfico foi desativado."
echo "Reinicie (sudo reboot) para entrar pela TTY."
echo "Backups dos arquivos alterados: /var/backups/noctalia-install-deb/"
echo "Para reativar depois: sudo systemctl enable --force greetd.service"
EOF
}

module_main() {
  step "07 — Configuração (atalhos, mouse, sessão, login)"
  deploy_hypr_config
  as_user xdg-user-dirs-update || true
  setup_greetd
  install_recovery_tool
  ok "Configuração concluída"
}

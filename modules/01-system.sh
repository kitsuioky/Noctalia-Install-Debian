#!/usr/bin/env bash
# 01-system.sh — prepara o sistema: ferramentas básicas e atualização.

module_main() {
  step "01 — Sistema base"
  apt_update
  apt_install ca-certificates curl wget gnupg git sudo xdg-user-dirs xdg-utils \
    dbus-user-session unzip zip p7zip-full less nano
  if [[ $NO_UPGRADE == 1 ]]; then
    info "full-upgrade pulado (--no-upgrade)"
  else
    info "atualizando o sistema (pode demorar)"
    DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
  fi
  ok "Sistema base pronto"
}

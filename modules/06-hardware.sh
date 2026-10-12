#!/usr/bin/env bash
# 06-hardware.sh — Wi-Fi, Bluetooth, áudio, firmware e microcódigo.

# O Debian mínimo costuma usar ifupdown no cabo. O NetworkManager (usado pelo Noctalia)
# ignora interfaces listadas em /etc/network/interfaces. Comentamos essas entradas
# (com backup); só vale depois do próximo boot, então a rede atual não cai agora.
free_interfaces_for_networkmanager() {
  local f=/etc/network/interfaces
  [[ -f $f ]] || return 0
  if grep -qE '^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+[^l[:space:]]' "$f"; then
    backup_path "$f"
    sed -i -E '/^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+lo([[:space:]]|$)/! s/^([[:space:]]*(auto|allow-hotplug|iface|wpa-|address|netmask|gateway|dns-))/# noctalia-install-deb: \1/' "$f"
    warn "/etc/network/interfaces: entradas comentadas (backup feito). O NetworkManager assume a rede após reiniciar."
  fi
}

module_main() {
  step "06 — Hardware (Wi-Fi, Bluetooth, áudio)"

  # Firmware e microcódigo
  apt_install_optional firmware-linux firmware-misc-nonfree
  if grep -qi 'GenuineIntel' /proc/cpuinfo; then apt_install_optional intel-microcode
  elif grep -qi 'AuthenticAMD' /proc/cpuinfo; then apt_install_optional amd64-microcode; fi

  # Rede / Wi-Fi
  apt_install network-manager wpasupplicant rfkill
  free_interfaces_for_networkmanager
  systemctl enable NetworkManager.service || warn "não consegui habilitar o NetworkManager"

  # Bluetooth
  apt_install bluez
  apt_install_optional libspa-0.2-bluetooth
  systemctl enable bluetooth.service || warn "não consegui habilitar o Bluetooth"

  # Áudio (PipeWire)
  apt_install pipewire pipewire-pulse pipewire-alsa wireplumber
  systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service \
    || warn "não consegui habilitar o PipeWire para os usuários"

  # Energia/brilho
  apt_install_optional power-profiles-daemon upower

  usermod -aG video,audio "$TARGET_USER"
  ok "Hardware configurado (reinicie para tudo valer)"
}

#!/usr/bin/env bash
# 05-applications.sh — apps do dia a dia (GNOME Software, Nautilus, Alacritty, Brave Origin e mais).

set_default_app() { # mimetype desktop-file
  local mime=$1 desktop=$2 cur
  [[ -e /usr/share/applications/$desktop ]] || return 0
  cur="$(as_user xdg-mime query default "$mime" 2>/dev/null || true)"
  if [[ -z $cur ]]; then as_user xdg-mime default "$desktop" "$mime" || true; fi
}

module_main() {
  step "05 — Aplicativos"

  # Obrigatórios do projeto
  apt_install nautilus alacritty gnome-software flatpak gvfs gvfs-backends
  apt_install_optional gnome-software-plugin-flatpak

  # Brave Origin
  if pkg_available brave-origin; then
    apt_install brave-origin
  else
    warn "brave-origin não está disponível agora — pulando (instale depois com: sudo apt install brave-origin)"
  fi

  # Flathub (loja de apps do GNOME Software)
  if command -v flatpak >/dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || warn "não consegui adicionar o Flathub agora"
  fi

  # Apps comuns
  apt_install_optional gnome-text-editor loupe gnome-calculator file-roller mpv \
    gnome-disk-utility gnome-system-monitor pavucontrol network-manager-gnome blueman \
    btop fastfetch ffmpegthumbnailer gnome-keyring
  apt_install_first papers evince >/dev/null || warn "nenhum leitor de PDF disponível"

  # Fontes (texto, ícones e emoji)
  apt_install_optional fonts-noto-core fonts-noto-color-emoji fonts-jetbrains-mono \
    fonts-font-awesome fonts-liberation

  if [[ $WITH_OFFICE == 1 ]]; then
    apt_install_optional libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gnome
  fi

  # Config do Alacritty (só cria se você ainda não tem uma)
  if [[ ! -e $TARGET_HOME/.config/alacritty/alacritty.toml ]]; then
    deploy_file "$ROOT_DIR/config/alacritty/alacritty.toml" \
      "$TARGET_HOME/.config/alacritty/alacritty.toml" "$TARGET_USER:$TARGET_GROUP"
  else
    info "alacritty.toml já existe — mantido como está"
  fi

  # Aplicativos padrão (só define o que você ainda não escolheu)
  set_default_app inode/directory org.gnome.Nautilus.desktop
  set_default_app text/plain org.gnome.TextEditor.desktop
  set_default_app image/png org.gnome.Loupe.desktop
  set_default_app image/jpeg org.gnome.Loupe.desktop
  set_default_app video/mp4 mpv.desktop
  set_default_app application/pdf org.gnome.Papers.desktop
  set_default_app x-scheme-handler/http brave-origin.desktop
  set_default_app x-scheme-handler/https brave-origin.desktop

  ok "Aplicativos instalados"
}

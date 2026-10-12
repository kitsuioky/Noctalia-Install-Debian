#!/usr/bin/env bash
# 08-plymouth.sh — tela de boot simples (opcional: só roda com --with-plymouth).
# Tema padrão: fundo escuro + logo Kyo. Futuro: --plymouth-repo URL usa um tema de um repositório git.

PLY_DIR=/usr/share/plymouth/themes

install_simple_theme() { # dest-dir logo.svg
  local dest=$1 logo=$2
  command -v rsvg-convert >/dev/null || { err "rsvg-convert não encontrado"; return 1; }
  mkdir -p "$dest"
  rsvg-convert -w 256 -h 256 "$logo" -o "$dest/logo.png" || return 1
  install -m 0644 "$ROOT_DIR/config/plymouth/kyo.plymouth" "$dest/kyo.plymouth"
  install -m 0644 "$ROOT_DIR/config/plymouth/kyo.script"   "$dest/kyo.script"
}

install_git_theme() { # url -> imprime o nome do tema
  local url=$1 tmp pfile name
  tmp="$(mktemp -d)"
  git clone --depth 1 "$url" "$tmp/theme" >&2 || { rm -rf "$tmp"; return 1; }
  pfile="$(find "$tmp/theme" -maxdepth 3 -name '*.plymouth' | head -1)"
  [[ -n $pfile ]] || { err "Nenhum arquivo .plymouth em $url" >&2; rm -rf "$tmp"; return 1; }
  name="$(basename "$pfile" .plymouth)"
  rm -rf "${PLY_DIR:?}/$name"; mkdir -p "$PLY_DIR/$name"
  cp -a "$(dirname "$pfile")/." "$PLY_DIR/$name/"
  rm -rf "$tmp"
  echo "$name"
}

enable_splash_in_grub() {
  local f=/etc/default/grub
  if [[ ! -f $f ]]; then warn "GRUB não encontrado. Adicione 'quiet splash' na linha de comando do kernel do seu bootloader."; return 0; fi
  if grep -qE '^GRUB_CMDLINE_LINUX_DEFAULT=.*splash' "$f"; then info "GRUB já tem 'splash'"; return 0; fi
  backup_path "$f"
  local cur new
  cur="$(sed -nE 's/^GRUB_CMDLINE_LINUX_DEFAULT="([^"]*)".*/\1/p' "$f" | head -1)"
  new="$cur"
  [[ " $new " == *" quiet "* ]] || new="$new quiet"
  new="$new splash"
  # shellcheck disable=SC2086
  new="$(echo $new)"                       # tira espaços sobrando
  sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=).*|\1\"$new\"|" "$f"
  update-grub || warn "update-grub falhou; rode manualmente: sudo update-grub"
  ok "GRUB: 'quiet splash' adicionado (backup feito)"
}

module_main() {
  step "08 — Plymouth (tela de boot)"
  if [[ $WITH_PLYMOUTH != 1 ]]; then info "pulado (use --with-plymouth para ativar)"; return 0; fi

  apt_install git ca-certificates plymouth plymouth-themes librsvg2-bin

  local theme=kyo logo
  if [[ -n $PLYMOUTH_THEME_REPO ]]; then
    theme="$(install_git_theme "$PLYMOUTH_THEME_REPO")" || { warn "Tema do git falhou — usando o tema simples do Kyo."; theme=kyo; PLYMOUTH_THEME_REPO=""; }
  fi
  if [[ -z $PLYMOUTH_THEME_REPO ]]; then
    logo="$TARGET_HOME/.local/src/kyo/assets/kyo.svg"
    [[ -f $logo ]] || logo="$ROOT_DIR/config/plymouth/kyo-logo.svg"
    install_simple_theme "$PLY_DIR/kyo" "$logo" || { warn "Não consegui montar o tema Kyo — Plymouth não alterado."; return 0; }
  fi

  plymouth-set-default-theme -R "$theme" || { warn "plymouth-set-default-theme falhou"; return 0; }
  enable_splash_in_grub
  ok "Plymouth ativo com o tema '$theme' (aparece no próximo boot)"
  warn "Se o boot der problema: no GRUB aperte 'e' e apague 'quiet splash' da linha do kernel."
}

#!/usr/bin/env bash
# 04-noctalia.sh — instala o shell: Kyo (kitsuioky/kyo) ou Noctalia original (noctalia-dev/noctalia).
#   --shell kyo|noctalia       : qual shell (sem a opção, o instalador pergunta).
#   --shell-source git (padrão): baixa do GitHub e compila.
#   --shell-source apt         : pacote oficial 'noctalia' (rápido, sem compilar; só Noctalia).
# Se o clone ou a compilação falhar, volta sozinho para o pacote 'noctalia' do apt.

# Dependências de compilação (BUILDING.md + meson.build + sua pesquisa).
# Nota: libcurl4-gnutls-dev (e não -openssl-dev) porque o libqalculate-dev do Debian depende da variante GnuTLS.
BUILD_DEPS=(
  meson g++ just git pkgconf python3 perl
  libwayland-dev wayland-protocols
  libegl-dev libgles-dev libepoxy-dev
  libfreetype-dev libfontconfig-dev
  libcairo2-dev libpango1.0-dev libharfbuzz-dev librsvg2-dev
  libxkbcommon-dev libglib2.0-dev
  libsecret-1-dev libsodium-dev
  libsdbus-c++-dev
  libpipewire-0.3-dev libwireplumber-0.5-dev
  libpam0g-dev libpolkit-agent-1-dev libpolkit-gobject-1-dev
  libcurl4-gnutls-dev libwebp-dev libjxl-dev libsndfile1-dev
  libqalculate-dev libxml2-dev
  libmd4c-dev libtomlplusplus-dev libical-dev
  nlohmann-json3-dev libstb-dev
  libjemalloc-dev
)

install_noctalia_from_apt() {
  pkg_available noctalia || die "O pacote 'noctalia' não aparece no repositório. Rode: sudo ./install.sh --only 02 --only 04   (ou tente --noctalia-build trixie)"
  apt_install noctalia
  apt_install_optional xdg-desktop-portal wlsunset power-profiles-daemon upower imagemagick
}

build_noctalia_from_git() {
  local name="${SHELL_CHOICE:-kyo}" repo tree
  local src="$TARGET_HOME/.local/src/$name" work="$TARGET_HOME/.cache/kyo-build"
  if [[ -n $SHELL_REPO ]]; then repo=$SHELL_REPO
  elif [[ $name == noctalia ]]; then repo=$NOCTALIA_REPO
  else repo=$KYO_REPO; fi

  # git: baixa se não tiver
  apt_install git ca-certificates || return 1

  info "Conferindo dependências de compilação..."
  require_all_available "${BUILD_DEPS[@]}" || return 1
  apt_install "${BUILD_DEPS[@]}" || return 1

  if [[ -n $SHELL_DIR ]]; then
    src="$(cd "$SHELL_DIR" 2>/dev/null && pwd)" || { err "Pasta não encontrada: $SHELL_DIR"; return 1; }
    [[ -f $src/meson.build && -d $src/src ]] || { err "$src não parece o código do shell (falta meson.build ou src/)."; return 1; }
    info "Usando a pasta local (sem GitHub): $src"
  else
    info "Baixando o shell ($name): $repo ($SHELL_REF)"
    sync_git_checkout "$repo" "$SHELL_REF" "$src" || { err "Não consegui baixar $repo (o repositório existe, é público e o branch '$SHELL_REF' existe?)"; return 1; }
  fi

  info "Compilando (pode levar vários minutos; o link final usa bastante RAM)..."
  as_user bash -c "cd '$src' && just configure release /usr/local && just build release" || return 1
  tree="$src"

  info "Instalando em /usr/local (como administrador)..."
  ( cd "$tree" && meson install --no-rebuild -C build-release ) || return 1

  # O binário compilado é quem decide qual shell ficou instalado.
  if [[ -x $tree/build-release/kyo && -x /usr/local/bin/kyo ]]; then
    SHELL_CHOICE=kyo; ok "Shell compilado e instalado em /usr/local/bin/kyo"
  elif [[ -x $tree/build-release/noctalia && -x /usr/local/bin/noctalia ]]; then
    SHELL_CHOICE=noctalia; ok "Shell compilado e instalado em /usr/local/bin/noctalia"
  else err "Nenhum binário (kyo ou noctalia) apareceu em /usr/local/bin."; return 1; fi
  export SHELL_CHOICE
}

module_main() {
  step "04 — Shell (${SHELL_CHOICE:-auto})"
  case "$SHELL_SOURCE" in
    git)
      if ! build_noctalia_from_git; then
        warn "Não deu para compilar ($SHELL_CHOICE). Usando o pacote 'noctalia' do repositório oficial."
        if [[ $SHELL_CHOICE == kyo ]]; then warn "ATENÇÃO: você pediu o Kyo, mas vai ficar o Noctalia original. Veja o log e rode: sudo ./install.sh --only 04 --shell kyo"; fi
        SHELL_CHOICE=noctalia
        install_noctalia_from_apt
      fi ;;
    apt) SHELL_CHOICE=noctalia; install_noctalia_from_apt ;;
    *) die "--shell-source inválido: $SHELL_SOURCE (use git ou apt)" ;;
  esac

  detect_shell_binary
  if command -v "$SHELL_BIN" >/dev/null 2>&1; then
    ok "Comando '$SHELL_BIN' disponível: $(command -v "$SHELL_BIN")"
  else
    warn "O comando '$SHELL_BIN' não apareceu no PATH."
  fi
}

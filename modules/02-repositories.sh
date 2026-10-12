#!/usr/bin/env bash
# 02-repositories.sh — Debian testing (contrib, non-free, non-free-firmware), Noctalia v5 e Brave Origin.

write_debian_sources() {
  # Usa o nome "testing" (e não o codinome) para não ficar preso a uma versão.
  deploy_stdin /etc/apt/sources.list.d/debian.sources <<'EOF'
# Gerenciado por Noctalia-install-deb
Types: deb
URIs: https://deb.debian.org/debian
Suites: testing
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  # Se o /etc/sources.list antigo ainda tem linhas ativas, faz backup e comenta (evita fonte duplicada).
  if [[ -f /etc/apt/sources.list ]] && grep -qE '^(deb|deb-src)[[:space:]]' /etc/apt/sources.list; then
    backup_path /etc/apt/sources.list
    sed -i -E 's/^(deb|deb-src)[[:space:]]/# desativado por Noctalia-install-deb: \1 /' /etc/apt/sources.list
    ok "/etc/apt/sources.list antigo comentado (backup feito)"
  fi
}

# Noctalia v5: chave (pacote .deb) + arquivo .sources oficiais de pkg.noctalia.dev/deb
add_noctalia_repo() {
  local suite other tmp src
  case "$NOCTALIA_BUILD" in
    auto|unstable|sid) suite=unstable ;;
    trixie) suite=trixie ;;
    *) die "--noctalia-build inválido: $NOCTALIA_BUILD (use auto, unstable ou trixie)" ;;
  esac
  info "Noctalia v5: usando o repositório '$suite'"

  tmp="$(mktemp --suffix=.deb)"
  curl -fsSL --retry 3 https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb -o "$tmp" \
    || { rm -f "$tmp"; die "Não consegui baixar a chave do repositório do Noctalia."; }
  dpkg -i "$tmp" || { rm -f "$tmp"; die "Falha ao instalar o keyring do Noctalia."; }
  rm -f "$tmp"

  src="$(curl -fsSL --retry 3 "https://pkg.noctalia.dev/deb/noctalia-$suite.sources")" && [[ -n $src ]] \
    || die "Não consegui baixar https://pkg.noctalia.dev/deb/noctalia-$suite.sources"
  printf '%s\n' "$src" | deploy_stdin "/etc/apt/sources.list.d/noctalia-$suite.sources"

  # Se você trocou de suite, remove o arquivo da outra (evita fonte duplicada)
  for other in trixie unstable; do
    [[ $other == "$suite" ]] && continue
    if [[ -f /etc/apt/sources.list.d/noctalia-$other.sources ]]; then
      backup_path "/etc/apt/sources.list.d/noctalia-$other.sources"
      rm -f "/etc/apt/sources.list.d/noctalia-$other.sources"
    fi
  done
}

add_brave_repo() {
  local src
  if ! fetch_key https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
       /usr/share/keyrings/brave-browser-archive-keyring.gpg raw; then
    warn "Brave: não consegui baixar a chave. O Brave Origin será pulado."; return 0
  fi
  if ! src="$(curl -fsSL --retry 3 https://brave-browser-apt-release.s3.brave.com/brave-browser.sources)" || [[ -z $src ]]; then
    warn "Brave: não consegui baixar a lista de fontes. O Brave Origin será pulado."; return 0
  fi
  printf '%s\n' "$src" | deploy_stdin /etc/apt/sources.list.d/brave-browser-release.sources
}

module_main() {
  step "02 — Repositórios"
  write_debian_sources
  apt_update
  add_noctalia_repo
  add_brave_repo
  apt_update
  ok "Repositórios configurados"
}

#!/usr/bin/env bash
# Noctalia-install-deb — transforma um Debian Testing mínimo em Hyprland + Noctalia.
# Uso: sudo ./install.sh [opções]    (veja --help)
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT_DIR
# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Noctalia-install-deb

Uso: sudo ./install.sh [opções]

  --only NN            roda só o módulo NN (ex.: --only 07). Pode repetir.
  --skip NN            pula o módulo NN (ex.: --skip 06). Pode repetir.
  --kb-layout XX       layout do teclado no Hyprland (padrão: br)
  --greeter NOME       noctalia (padrão), tuigreet ou gtkgreet
  --noctalia-build B   auto (padrão = unstable), unstable ou trixie
  --shell NOME         kyo ou noctalia (sem isso, o instalador pergunta; sem terminal usa kyo)
  --shell-source S     git (padrão: baixa e compila) ou apt (pacote oficial 'noctalia')
  --shell-repo URL     usa outro repositório no lugar do padrão da escolha
                       (kyo: https://github.com/kitsuioky/kyo.git | noctalia: https://github.com/noctalia-dev/noctalia.git)
  --shell-ref REF      branch ou tag (padrão: main)
  --shell-dir PASTA    compila uma pasta local com o código do shell (não precisa de GitHub)
  --with-plymouth      instala o Plymouth com um tema simples do Kyo (tela de boot)
  --plymouth-repo URL  usa um tema Plymouth de um repositório git (em vez do tema simples)
  --with-office        instala também o LibreOffice (pesado)
  --no-upgrade         não roda o full-upgrade do sistema
  -h, --help           mostra esta ajuda

É seguro rodar de novo: nada é apagado e todo arquivo alterado vai para backup.
Logs:    /var/log/noctalia-install-deb/
Backups: /var/backups/noctalia-install-deb/
Se algo der errado no login gráfico: Ctrl+Alt+F2 e rode  sudo noctalia-recover
EOF
}

ONLY=(); SKIP=()
while (( $# )); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --only) ONLY+=("${2:?falta valor}"); shift 2 ;;
    --skip) SKIP+=("${2:?falta valor}"); shift 2 ;;
    --kb-layout) KB_LAYOUT="${2:?falta valor}"; shift 2 ;;
    --greeter) GREETER="${2:?falta valor}"; shift 2 ;;
    --noctalia-build) NOCTALIA_BUILD="${2:?falta valor}"; shift 2 ;;
    --shell) SHELL_CHOICE="${2:?falta kyo ou noctalia}"; shift 2 ;;
    --shell-source) SHELL_SOURCE="${2:?falta valor}"; shift 2 ;;
    --shell-repo) SHELL_REPO="${2:?falta valor}"; shift 2 ;;
    --shell-ref) SHELL_REF="${2:?falta valor}"; shift 2 ;;
    --shell-dir) SHELL_DIR="${2:?falta valor}"; SHELL_SOURCE=git; shift 2 ;;
    --with-plymouth) WITH_PLYMOUTH=1; shift ;;
    --plymouth-repo) PLYMOUTH_THEME_REPO="${2:?falta valor}"; WITH_PLYMOUTH=1; shift 2 ;;
    --with-office) WITH_OFFICE=1; shift ;;
    --no-upgrade) NO_UPGRADE=1; shift ;;
    *) die "opção desconhecida: $1 (use --help)" ;;
  esac
done
export SHELL_CHOICE KB_LAYOUT GREETER NOCTALIA_BUILD WITH_OFFICE NO_UPGRADE SHELL_SOURCE SHELL_REPO SHELL_REF SHELL_DIR WITH_PLYMOUTH PLYMOUTH_THEME_REPO

case "$SHELL_CHOICE" in ""|kyo|noctalia) ;; *) die "--shell deve ser 'kyo' ou 'noctalia' (recebi: $SHELL_CHOICE)" ;; esac
case "$SHELL_SOURCE" in git|apt) ;; *) die "--shell-source deve ser 'git' ou 'apt' (recebi: $SHELL_SOURCE)" ;; esac
if [[ $SHELL_SOURCE == apt && $SHELL_CHOICE == kyo ]]; then die "O Kyo não tem pacote apt. Use --shell noctalia com --shell-source apt, ou tire o --shell-source."; fi
[[ $SHELL_SOURCE == apt ]] && SHELL_CHOICE=noctalia

require_root
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$TIMESTAMP.log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'err "Falhou na linha $LINENO (comando: $BASH_COMMAND). Log: $LOG_FILE"' ERR

step "$PROJECT_NAME — início ($TIMESTAMP)"
detect_target_user
check_system
cleanup_legacy_noctalia_repo

in_list() { local x=$1; shift; local i; for i in "$@"; do [[ $i == "$x" ]] && return 0; done; return 1; }

# Só pergunta qual shell instalar se o módulo 04 vai rodar.
runs_04=1
if (( ${#ONLY[@]} )) && ! in_list 04 "${ONLY[@]}"; then runs_04=0; fi
if (( ${#SKIP[@]} )) && in_list 04 "${SKIP[@]}"; then runs_04=0; fi
(( runs_04 )) && choose_shell
detect_shell_binary

for module in "$ROOT_DIR"/modules/[0-9][0-9]-*.sh; do
  id="$(basename "$module")"; id="${id:0:2}"
  if (( ${#ONLY[@]} )) && ! in_list "$id" "${ONLY[@]}"; then continue; fi
  if (( ${#SKIP[@]} )) && in_list "$id" "${SKIP[@]}"; then info "pulando módulo $id"; continue; fi
  # shellcheck disable=SC1090
  source "$module"
  module_main
  unset -f module_main
done

step "Pronto!"
ok "Log: $LOG_FILE"
ok "Backups (se houve alterações): $BACKUP_DIR"
cat <<EOF

Próximo passo:  sudo reboot
Na tela de login escolha a sessão Hyprland e entre com seu usuário.
Atalhos e mouse: veja docs/MOUSE.md  (Super+Enter = terminal, Super+Espaço = launcher)
Se travar: Ctrl+Alt+F2, faça login e rode:  sudo noctalia-recover
EOF

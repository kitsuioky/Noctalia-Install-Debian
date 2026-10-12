#!/usr/bin/env bash
# lib/common.sh — funções compartilhadas: mensagens, logs, apt, backup e validações.

: "${KB_LAYOUT:=br}"
: "${GREETER:=noctalia}"
: "${NOCTALIA_BUILD:=auto}"   # auto (=unstable) | unstable | trixie
: "${WITH_OFFICE:=0}"
: "${NO_UPGRADE:=0}"
: "${SHELL_SOURCE:=git}"     # git (baixa e compila) | apt (pacote oficial 'noctalia')
: "${SHELL_CHOICE:=}"        # kyo | noctalia (vazio = pergunta; sem terminal usa kyo)
: "${KYO_REPO:=https://github.com/kitsuioky/kyo.git}"
: "${NOCTALIA_REPO:=https://github.com/noctalia-dev/noctalia.git}"
: "${SHELL_REPO:=}"          # opcional: força outro repositório (vale para a escolha atual)
: "${SHELL_REF:=main}"
: "${SHELL_DIR:=}"             # pasta local com o código do shell (compila sem GitHub)
: "${WITH_PLYMOUTH:=0}"
: "${SHELL_BIN:=noctalia}"                  # nome do comando do shell (vira "kyo" se o seu fork renomeou tudo)
: "${SHELL_APPID:=dev.noctalia.Noctalia}"
: "${PLYMOUTH_THEME_REPO:=}"  # opcional: repositório git com um tema Plymouth pronto

PROJECT_NAME="Noctalia-install-deb"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/var/backups/noctalia-install-deb/$TIMESTAMP"
LOG_DIR="/var/log/noctalia-install-deb"

if [[ -t 1 ]]; then
  C_RESET=$'\e[0m'; C_RED=$'\e[31m'; C_GRN=$'\e[32m'; C_YEL=$'\e[33m'; C_BLU=$'\e[34m'
else
  C_RESET=''; C_RED=''; C_GRN=''; C_YEL=''; C_BLU=''
fi

# ---------- mensagens ----------
info() { printf '%s[..]%s %s\n' "$C_BLU" "$C_RESET" "$*"; }
ok()   { printf '%s[ok]%s %s\n' "$C_GRN" "$C_RESET" "$*"; }
warn() { printf '%s[!!]%s %s\n' "$C_YEL" "$C_RESET" "$*" >&2; }
err()  { printf '%s[xx]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }
step() { printf '\n%s==> %s%s\n' "$C_BLU" "$*" "$C_RESET"; }

# ---------- verificações do sistema ----------
require_root() {
  [[ $EUID -eq 0 ]] || die "Rode com sudo:  sudo ./install.sh"
}

detect_target_user() {
  TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
  if [[ -z $TARGET_USER || $TARGET_USER == root ]]; then
    die "Não achei seu usuário normal. Use 'sudo ./install.sh' no seu usuário, ou rode como root assim: TARGET_USER=seuusuario ./install.sh"
  fi
  id "$TARGET_USER" >/dev/null 2>&1 || die "Usuário '$TARGET_USER' não existe."
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  TARGET_GROUP="$(id -gn "$TARGET_USER")"
  export TARGET_USER TARGET_HOME TARGET_GROUP
}

check_system() {
  [[ -r /etc/os-release ]] || die "/etc/os-release não encontrado."
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ ${ID:-} == debian ]] || die "Este instalador é só para Debian (detectado: ${ID:-desconhecido})."
  [[ "$(dpkg --print-architecture)" == amd64 ]] || die "Só 64 bits (amd64) por enquanto."
  command -v systemctl >/dev/null || die "systemd não encontrado."
  command -v curl >/dev/null || { apt-get update && apt-get install -y curl ca-certificates; }
  curl -fsI --max-time 15 https://deb.debian.org >/dev/null 2>&1 || die "Sem internet (não consegui acessar deb.debian.org)."
  ok "Sistema ok: Debian ${VERSION_CODENAME:-?}, amd64, usuário alvo: $TARGET_USER"
}

# ---------- backup e gravação de arquivos ----------
backup_path() {
  local p=$1
  [[ -e $p ]] || return 0
  mkdir -p "$BACKUP_DIR$(dirname "$p")"
  cp -a "$p" "$BACKUP_DIR$p"
  info "backup: $p -> $BACKUP_DIR$p"
}

ensure_parent() { # dest owner
  local d; d="$(dirname "$1")"
  [[ -d $d ]] && return 0
  if [[ ${2%%:*} == root ]]; then mkdir -p "$d"; else runuser -u "${2%%:*}" -- mkdir -p "$d"; fi
}

# Lê o conteúdo do stdin e grava em $1. Só mexe se o conteúdo mudou; faz backup antes.
deploy_stdin() { # dest [owner] [mode]
  local dest=$1 owner=${2:-root:root} mode=${3:-0644} tmp
  tmp="$(mktemp)"; cat >"$tmp"
  if [[ -f $dest ]] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"; info "já está atualizado: $dest"; return 0
  fi
  if [[ -e $dest ]]; then backup_path "$dest"; fi
  ensure_parent "$dest" "$owner"
  install -m "$mode" -o "${owner%%:*}" -g "${owner##*:}" "$tmp" "$dest"
  rm -f "$tmp"; ok "gravado: $dest"
}

# Copia um modelo de config/ trocando os @PLACEHOLDERS@.
deploy_file() { # src dest [owner] [mode]
  local appid_re="${SHELL_APPID//./\\.}"            # dev\.kyo\.Kyo (para regex)
  appid_re="${appid_re//\\/\\\\}"                   # duplica a barra para o sed
  sed -e "s|@KB_LAYOUT@|${KB_LAYOUT}|g" \
      -e "s|@SHELL_BIN@|${SHELL_BIN}|g" \
      -e "s|@SHELL_APPID_RE@|${appid_re}|g" \
      -e "s|@SHELL_APPID@|${SHELL_APPID}|g" "$1" | deploy_stdin "$2" "${3:-root:root}" "${4:-0644}"
}

# ---------- apt ----------
apt_update() { apt-get update -o Acquire::Retries=3; }

pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

pkg_available() {
  local c; c="$(LC_ALL=C apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}')"
  [[ -n $c && $c != '(none)' ]]
}

apt_install() { # obrigatórios: falha se der erro
  local missing=() p
  for p in "$@"; do pkg_installed "$p" || missing+=("$p"); done
  (( ${#missing[@]} )) || return 0
  info "instalando: ${missing[*]}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
}

apt_install_optional() { # opcionais: só avisa se não existir ou falhar
  local p
  for p in "$@"; do
    if pkg_installed "$p"; then continue; fi
    if pkg_available "$p"; then
      apt_install "$p" || warn "falhou ao instalar (opcional): $p"
    else
      warn "pacote não existe no repositório (pulando): $p"
    fi
  done
}

# Instala o primeiro pacote disponível da lista; imprime o nome escolhido.
apt_install_first() {
  local p
  for p in "$@"; do
    if pkg_available "$p"; then apt_install "$p" >&2 && { echo "$p"; return 0; }; fi
  done
  return 1
}

# ---------- chaves e versões ----------
fetch_key() { # url dest [raw|dearmor]
  local url=$1 dest=$2 mode=${3:-raw} tmp
  tmp="$(mktemp)"
  if ! curl -fsSL --retry 3 "$url" -o "$tmp" || [[ ! -s $tmp ]]; then rm -f "$tmp"; return 1; fi
  mkdir -p "$(dirname "$dest")"
  if [[ $mode == dearmor ]]; then gpg --batch --yes --dearmor -o "$dest" "$tmp"; else install -m 0644 "$tmp" "$dest"; fi
  chmod 0644 "$dest"; rm -f "$tmp"
}

# ---------- validação ----------
CHECK_FAIL=0; CHECK_WARN=0
check_ok()   { ok "$*"; }
check_fail() { err "FALTA: $*"; CHECK_FAIL=$((CHECK_FAIL+1)); }
check_warn() { warn "$*"; CHECK_WARN=$((CHECK_WARN+1)); }
check_cmd()  { if command -v "$1" >/dev/null 2>&1; then check_ok "comando: $1"; else check_fail "comando: $1"; fi; }
check_pkg()  { if pkg_installed "$1"; then check_ok "pacote: $1"; else check_fail "pacote: $1"; fi; }
check_file() { if [[ -e $1 ]]; then check_ok "arquivo: $1"; else check_fail "arquivo: $1"; fi; }

# O repositório antigo do Noctalia v4 (pkg.noctalia.dev/apt) foi desativado e dá 404.
# Remove restos dele (com backup) para o apt update não quebrar.
cleanup_legacy_noctalia_repo() {
  local f
  for f in /etc/apt/sources.list.d/noctalia.sources /etc/apt/sources.list.d/noctalia.list; do
    if [[ -f $f ]] && grep -q 'pkg.noctalia.dev/apt' "$f"; then
      backup_path "$f"; rm -f "$f"
      warn "repositório antigo do Noctalia (v4) removido: $f"
    fi
  done
}

# Versão do Hyprland instalada (ou candidata), sem época. Ex.: 0.55.2-2
hyprland_version() {
  local v
  v="$(dpkg-query -W -f='${Version}' hyprland 2>/dev/null || true)"
  [[ -n $v ]] || v="$(LC_ALL=C apt-cache policy hyprland 2>/dev/null | awk '/Candidate:/{print $2}')"
  [[ -n $v && $v != '(none)' ]] || v=0
  echo "${v#*:}"
}

# Hyprland >= 0.55 usa config em Lua (hyprland.lua); antes usava hyprlang (hyprland.conf).
hyprland_config_mode() {
  if dpkg --compare-versions "$(hyprland_version)" ge 0.55; then echo lua; else echo conf; fi
}

# Roda um comando COMO o usuário alvo, com HOME certo (runuser -u sozinho pode manter o HOME do root).
as_user() { runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" USER="$TARGET_USER" LOGNAME="$TARGET_USER" "$@"; }

# Confere se TODOS os pacotes existem no apt; lista os que faltam (como o teste 7a da sua pesquisa).
require_all_available() {
  local missing=() p
  for p in "$@"; do pkg_available "$p" || missing+=("$p"); done
  if (( ${#missing[@]} )); then err "Pacotes não encontrados no Debian agora: ${missing[*]}"; return 1; fi
}

# Clona (ou atualiza) um repositório git na pasta $3, como o usuário alvo. Não apaga mudanças locais.
sync_git_checkout() { # url ref dest
  local url=$1 ref=$2 dest=$3
  as_user mkdir -p "$(dirname "$dest")" || return 1
  if [[ -d $dest/.git ]]; then
    if [[ -n "$(as_user git -C "$dest" status --porcelain 2>/dev/null)" ]]; then
      warn "$dest tem mudanças locais — não atualizei (usando como está)"; return 0
    fi
    as_user git -C "$dest" fetch --depth 1 origin "$ref" || return 1
    as_user git -C "$dest" reset --hard FETCH_HEAD || return 1
  else
    as_user git clone --depth 1 --branch "$ref" "$url" "$dest" || return 1
  fi
}

# Pergunta qual shell instalar (só se --shell não foi passado). Opções:
#   1) Kyo (kitsuioky/kyo, compila)   2) Noctalia original (compila)   3) Noctalia original (pacote apt)
choose_shell() {
  if [[ -n $SHELL_CHOICE ]]; then return 0; fi
  if [[ -n $SHELL_DIR ]]; then return 0; fi   # pasta local: o instalador descobre pelo binário compilado
  local ans=""
  echo
  echo "Qual shell você quer instalar?"
  echo "  1) Kyo        — $KYO_REPO (compila)"
  echo "  2) Noctalia   — $NOCTALIA_REPO (original, compila)"
  echo "  3) Noctalia   — pacote 'noctalia' do apt (original, rápido, sem compilar)"
  if { : </dev/tty; } 2>/dev/null; then
    read -r -p "Escolha [1/2/3] (padrão: 1): " ans </dev/tty || true
  else
    echo "(sem terminal interativo, usando o padrão: Kyo)"
  fi
  case "${ans:-1}" in
    1|kyo|Kyo) SHELL_CHOICE=kyo ;;
    2|noctalia|Noctalia) SHELL_CHOICE=noctalia ;;
    3|apt) SHELL_CHOICE=noctalia; SHELL_SOURCE=apt ;;
    *) die "Opção inválida: $ans" ;;
  esac
  export SHELL_CHOICE SHELL_SOURCE
}

# Descobre qual shell está instalado: "kyo" (fork com tudo renomeado) ou "noctalia" (original).
detect_shell_binary() {
  if [[ $SHELL_CHOICE == kyo ]]; then
    SHELL_BIN=kyo; SHELL_APPID=dev.kyo.Kyo
  elif [[ $SHELL_CHOICE == noctalia ]]; then
    SHELL_BIN=noctalia; SHELL_APPID=dev.noctalia.Noctalia
  elif [[ -x /usr/local/bin/kyo ]] || command -v kyo >/dev/null 2>&1; then
    SHELL_BIN=kyo; SHELL_APPID=dev.kyo.Kyo
  else
    SHELL_BIN=noctalia; SHELL_APPID=dev.noctalia.Noctalia
  fi
  export SHELL_BIN SHELL_APPID
}

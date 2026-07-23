#!/usr/bin/env bash

## CLY - A Semantic AUR Helper wrapper written in bash

ver="7.5.3"; rc="release-1"

set -o pipefail

REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" 2>/dev/null | cut -d: -f6); REAL_HOME=${REAL_HOME:-$HOME}
CONFIG_FOLDER="$REAL_HOME/.local/share/cly"
LOG_FILE="$REAL_HOME/.cache/cly.log"
BACKUP_DIR="$CONFIG_FOLDER/backup"
BACKUP_FILE="$BACKUP_DIR/backup.txt"
MODULES_FOLDER="/usr/share/cly"

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

COMPLETE="[✓]"
ALERT="[!]"
ERROR="[X]"
NOTE="[*]"
CC="->"

detback() {
    for b in yay paru; do
        command -v "$b" &>/dev/null && backend="$b" && return
    done
    backend="pacman"
}

load_lang() {
    lang_code="${LANG:0:2}"
    [[ ! -f "$MODULES_FOLDER/languages/lang_mod_pt.sh" && "$lang_code" == "pt" ]] && echo -e "${RED} $ERROR${NC} Módulo do idioma 'lang_mod_pt.sh' não encontrado." && exit 1
    [[ ! -f "$MODULES_FOLDER/languages/lang_mod_en.sh" && "$lang_code" == "en" ]] && echo -e "${RED} $ERROR${NC} Language module 'lang_mod_en.sh' not found." && exit 1
    case "$lang_code" in
        pt) source "$MODULES_FOLDER/languages/lang_mod_pt.sh" ;;
        *)  source "$MODULES_FOLDER/languages/lang_mod_en.sh" ;;
    esac
}

load_lang

logback() {
    echo -e "${GREEN}${BOLD}$CC $M_USING_BACKEND $backend...${NC}"
}

st() { echo -e "${BOLD}${GREEN} $CC ${NC}${1}"; }
sc() { echo -e "${GREEN} $COMPLETE ${NC}${1}"; }
err() { echo -e "${RED} $ERROR ${NC}${1}"; exit 1; }
error() { err "$1"; }
usage() { echo "$H_USAGE: cly [$USG1] [$USG2] [$USG3]"; exit 1; }

modules_test=0

load_modules() {
    [[ "$modules_test" == "1" ]] && echo -e "MODULES TEST: Modules Folder: $MODULES_FOLDER"
    local failed=()
    for mod in mod_01.sh mod_02.sh mod_03.sh mod_04.sh mod_05.sh; do
        [[ ! -f "$MODULES_FOLDER/$mod" ]] && failed+=("$mod")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        [[ "$lang_code" == "pt" ]] && echo -e "${RED} ${ERROR} ${NC}Módulos não encontrados: ${failed[*]}" || \
        echo -e "${RED} ${ERROR} ${NC}Modules not found: ${failed[*]}"
        exit 1
    fi
    for mod in mod_01.sh mod_02.sh mod_03.sh mod_04.sh mod_05.sh; do
        source "$MODULES_FOLDER/$mod"
    done
}

load_modules

[[ -f "$LOG_FILE" ]] || : > "$LOG_FILE"
[[ ! -w "$LOG_FILE" ]] && sudo chown "${SUDO_USER:-$USER}":"${SUDO_USER:-$USER}" "$LOG_FILE" 2>/dev/null
[[ -z "$1" ]] && help_message

only_flatpak=0
final_args=()
back_flags=()
log_lines=""
raw_cmd="$*"
agrmode=0
dry_run=0
do_snap=0
ptbin=0
lsaur=0
func=""
flat=0
mlog=1

log_rotate
load_lang
detback

[[ "$backend" == "pacman" && "$EUID" -ne 0 ]] && err "$E_07"
[[ "$backend" != "pacman" && "$EUID" -eq 0 ]] && err "$E_05"

while [[ $# -gt 0 ]]; do
    case "$1" in
        updater|doctor|ra|--create-snapshot|dp|why|--ignore|pin|statsb|--pacdiff|--ping|--create-backup|--restore-backup|install|-i|remove|-r|update|-u|search|-s|query|-q|cache|-c|orphan|-o|mirrors|-m|slog|-cl|-sl|--fix-keys|--check-updates)
            [[ -z "$action" ]] && action="$1" || final_args+=("$1")
        ;;
        mksnap|--create-snapshot)  do_snap="1" ;;
        --list-aur|-ls-aur)        lsaur=1 ;;
        -fo|--flatpak-only)        only_flatpak=1 ;;
        --path-to-binary)          ptbin=1 ;;
        -nc|--noconfirm)           back_flags+=("--noconfirm") ;;
        -v|--version)              dpver; exit 0 ;;
        -f|--flatpak)              flat=1 ;;
        --testing)                 MODULES_FOLDER="./modules"; modules_test=1; load_modules ;;
        --backend)                 shift; if [[ "$1" == "yay" || "$1" == "paru" ]]; then backend="$1"; else err "$E_04"; fi ;;
        --dry-run)                 dry_run=1 ;;
        -h|--help)                 help_message ;;
        --no-log)                  mlog=0 ;;
        --lines)                   shift; log_lines="$1" ;;
        --debug)                   set -x ;;
        --view)                    [[ -z "$action" ]] && action="--view" || final_args+=("$1") ;;
        --path)                    shift; [[ -z "$1" ]] && error "--path requires a file path argument"; custom_path="$1" ;;
        --info)                    inform; exit 0 ;;
        *)                         final_args+=("$1") ;;
    esac
    shift
done

[[ -z "$action" && ${#final_args[@]} -gt 0 ]] && action="${final_args[0]}" && final_args=("${final_args[@]:1}")
[[ "$action" =~ ^(-S|-in|ins|install|-i|-Rsn|-ra|--remove-agressive|ra|-R|rem|remove|-r|-rm)$ && ${#final_args[@]} -eq 0 ]] && error "$M_SPECIFY_PKG"
! command -v "$backend" &>/dev/null && load_lang && err "$E_03"
tmp_out=$(mktemp) || err "$E_02"
trap 'rm -f "$tmp_out" 2>/dev/null' EXIT

if [[ -f /var/lib/pacman/db.lck ]]; then
    { pgrep -x pacman >/dev/null || pgrep -x "$backend" >/dev/null; } && error "$M_PACMAN_RUNNING"
    sudo rm /var/lib/pacman/db.lck && sc "$M_LOCK_REMOVED"
fi

[[ "$only_flatpak" == "1" ]] && flatpak_only

case "$action" in
    -Rsn|-ra|--remove-agressive|ra)    logback; agrmode=1; func="r"; proc_func ;;
    --check-upds|--check-updates)      logback; check_updates ;;
    mksnap|--create-snapshot)          mksnap; exit 0 ;;
    -Syu|-up|upd|update|-u)            logback; func="u"; proc_func ;;
    -S|-in|ins|install|-i)             logback; func="i"; proc_func ;;
    --clear-logs|clog|-cl)             log_func="cl"; proc_log_func ;;
    -Ss|-sr|src|search|-s)             logback; func="s"; proc_func ;;
    --stats|--statistics)              show_stats ;;
    --show-logs|slog|-sl)              log_func="sl"; proc_log_func ;;
    -rb|--restore-backup)              backup_action="restore"; backup_func ;;
    -R|rem|remove|-r|-rm)              logback; func="r"; proc_func ;;
    -Q|-qr|qur|query|-q)               logback; func="q"; proc_func ;;
    -cb|--create-backup)               backup_action="create"; backup_func ;;
    -mr|mir|mirrors|-m)                refresh_mirrors ;;
    -op|orp|orphan|-o)                 logback; rmorps ;;
    -cc|cac|cache|-c)                  logback; chmgr ;;
    pin|--ignore)                      pin ;;
    depends|why)                       depends ;;
    --fix-keys)                        fix_keys ;;
    -vi|--view)                        logback; view_pkgbuild "${final_args[0]}"; exit 0 ;;
    --pacdiff)                         logback; ckconf ;;
    updater)                           cly_updater ;;
    doctor)                            doctor ;;
    --ping)                            ntest; exit 0 ;;
    *)                                 err "$E_01 '$action'" ;;
esac

[[ "$tag" == "SKIP" ]] && exit 0

if [[ "$dry_run" == "1" ]]; then
    echo -e "\n${YELLOW}$M_DRY_RUN_SIM${NC}"
    [[ -n "$cmd" ]] && echo -e "${CYAN}$M_DRY_RUN_RUN${NC} $backend $cmd ${final_args[*]} ${back_flags[*]}"
    [[ "$flat" == "1" && -n "$flat_cmd" ]] && echo -e "${CYAN}$M_DRY_RUN_RUN${NC} flatpak $flat_cmd ${final_args[*]}"
    echo -e "${GREEN}$M_DRY_RUN_NONE${NC}\n"
    exit 0
fi

case "$action" in
    search|-s)
        "$backend" "$cmd" "${final_args[@]}" "${back_flags[@]}" 2>&1 | tee "$tmp_out"
        exit_code=${PIPESTATUS[0]}
        rflat
    ;;
    *)
        if [[ -n "$cmd" ]]; then
            log_type="2" && mklog "Executing $backend $cmd ${final_args[@]} ${back_flags[@]}"
            "$backend" "$cmd" "${final_args[@]}" "${back_flags[@]}" 2>&1 | tee "$tmp_out"
            exit_code=${PIPESTATUS[0]}
            rflat
        fi
    ;;
esac

if [[ "$exit_code" -eq 0 && -n "$tag" ]]; then
    if grep -qiE "could not find|nenhum pacote|target not found" "$tmp_out"; then
        mklog "NOT FOUND" "${raw_cmd}"
    else
        mklog "${tag:-SYSTEM}" "${raw_cmd}"
    fi
fi

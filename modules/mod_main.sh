#!/usr/bin/env bash

## CLY - A Semantic AUR Helper wrapper written in bash

ver="7.5.9"
rc="release-1"

set -o pipefail

### Essential variables ###

REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" 2>/dev/null | cut -d: -f6); REAL_HOME=${REAL_HOME:-$HOME}
LOCAL_FOLDER="$REAL_HOME/.local/share/cly"
LOG_FILE="$REAL_HOME/.cache/cly.log"
CONFIG_FOLDER="$REAL_HOME/.config/cly"
BACKUP_DIR="$LOCAL_FOLDER/backup"
BACKUP_FILE="$BACKUP_DIR/backup.txt"
MODULES_FOLDER="/usr/share/cly"

### Config file functios ###

def() {
    local param="$1"
    local value="$2"
    case "$param" in
        "SHOW_COLORS")
            case "$value" in
                true)  SHOW_COLORS="1" ;;
                false) SHOW_COLORS="0" ;;
                *)     SHOW_COLORS="1" ;;
            esac
        ;;
        "MAX_LOG_SIZE")
            if (( value <= 100 )); then
                echo "Error in config file: MAX_LOG_SIZE value is too small"
                exit 1
                elif (( value <= 1000000 )); then
                MAX_LOG_SIZE="$value"
                elif (( value > 100000 )); then
                MAX_LOG_SIZE="infinite"
            fi
            
        ;;
        "ALWAYS_USE_NOCONFIRM")
            always_no_confirm="false"
            case "$value" in
                true)  always_no_confirm="true"  ;;
                false) always_no_confirm="false" ;;
                *)     always_no_confirm="false" ;;
            esac
        ;;
        "ENABLE_LOGGING")
            case "$value" in
                true)   LOGGING="true"  ;;
                false)  LOGGING="false" ;;
                *)      LOGGING="true"  ;;
            esac
        ;;
        "AUTO_SNAPSHOT_ON_UPDATE")
            case "$value" in
                true)  AUTO_SNAPSHOT="true"  ;;
                false) AUTO_SNAPSHOT="false" ;;
                *)     AUTO_SNAPSHOT="true"  ;;
            esac
        ;;
        "NETWORK_TESTING")
            case "$value" in
                true)  NETWORK_TEST="true"  ;;
                false) NETWORK_TEST="false" ;;
                *)     NETWORK_TEST="true"  ;;
            esac
        ;;
        "DEFAULT_BACKEND")
            case "$value" in
                yay)    DEFAULT_BACKEND="yay"     ;;
                paru)   DEFAULT_BACKEND="paru"    ;;
                pacman) DEFAULT_BACKEND="pacman"  ;; ## Why would you do this?
                auto)   DEFAULT_BACKEND="auto"    ;;
                *)      DEFAULT_BACKEND="auto"    ;;
            esac
        ;;
        "MALWARE_CHECK")
            case "$value" in
                true)  MALWARE_CHECK="true"  ;;
                false) MALWARE_CHECK="false" ;;
                *)     MALWARE_CHECK="true"  ;;
            esac
        ;;
    esac
}

### Config loader ###

migrate_config() {
    local missing; missing=$(comm -23 <(grep -oP '(?<=def ")[^"]+' "$MODULES_FOLDER/components/example_config" | sort) <(grep -oP '(?<=def ")[^"]+' "$CONFIG_FOLDER/config" | sort))
    if [[ -n "$missing" ]]; then
        cp "$CONFIG_FOLDER/config" "$CONFIG_FOLDER/config.bak"
        while IFS= read -r key; do
            local line; line=$(grep "def \"$key\"" "$MODULES_FOLDER/components/example_config")
            echo "$line" >> "$CONFIG_FOLDER/config"
        done < <(echo "$missing")
        echo -e "${YELLOW} $NOTE $M_CONFIG_MIGRATED${NC}"
    fi
}

load_config() {
    [[ ! -f "$CONFIG_FOLDER/config" ]] && install -Dm644 -o "${SUDO_USER:-$USER}" -g "${SUDO_USER:-$USER}" "$MODULES_FOLDER/base_config" "$CONFIG_FOLDER/config"
    migrate_config
    source "$CONFIG_FOLDER/config"
}

load_config

### Variables ###

if [[ $SHOW_COLORS == "1" ]]; then
    NC='\033[0m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
else
    NC=''
    RED=''
    BOLD=''
    CYAN=''
    GREEN=''
    YELLOW=''
fi

CC="->"
NOTE="[*] "
ERROR="[X] "
ALERT="[!] "
COMPLETE="[✓] "

### Basic functions ###

detback() {
    if [[ "$DEFAULT_BACKEND" != "auto" ]]; then
        command -v "$DEFAULT_BACKEND" &>/dev/null && backend="$DEFAULT_BACKEND"
    else
        for b in yay paru; do
            command -v "$b" &>/dev/null && backend="$b" && return
        done
        backend="pacman"
    fi
}

load_lang() {
    lang_code="${LANG:0:2}"
    [[ ! -f "$MODULES_FOLDER/languages/lang_mod_pt.sh" && "$lang_code" == "pt" ]] && echo -e "${RED} $ERROR${NC} Módulo do idioma 'lang_mod_pt.sh' não encontrado." && exit 1
    [[ ! -f "$MODULES_FOLDER/languages/lang_mod_es.sh" && "$lang_code" == "es" ]] && echo -e "${RED} $ERROR${NC} Módulo de idioma 'lang_mod_es.sh' no encontrado." && exit 1
    [[ ! -f "$MODULES_FOLDER/languages/lang_mod_en.sh" && "$lang_code" == "en" ]] && echo -e "${RED} $ERROR${NC} Language module 'lang_mod_en.sh' not found." && exit 1
    case "$lang_code" in
        pt) source "$MODULES_FOLDER/languages/lang_mod_pt.sh" ;;
        es) source "$MODULES_FOLDER/languages/lang_mod_es.sh" ;;
        *)  source "$MODULES_FOLDER/languages/lang_mod_en.sh" ;;
    esac
}

load_lang

logback() {
    st "$M_USING_BACKEND ${backend}..."
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
        [[ ! -f "$MODULES_FOLDER/execution-modules/$mod" ]] && failed+=("$mod")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        [[ "$lang_code" == "pt" ]] && echo -e "${RED} ${ERROR} ${NC}Módulos não encontrados: ${failed[*]}" || \
        echo -e "${RED} ${ERROR} ${NC}Modules not found: ${failed[*]}"
        exit 1
    fi
    for mod in mod_01.sh mod_02.sh mod_03.sh mod_04.sh mod_05.sh; do
        source "$MODULES_FOLDER/execution-modules/$mod"
    done
}

load_modules

[[ -f "$LOG_FILE" ]] || : > "$LOG_FILE"
[[ ! -w "$LOG_FILE" ]] && sudo chown "${SUDO_USER:-$USER}":"${SUDO_USER:-$USER}" "$LOG_FILE" 2>/dev/null
[[ -z "$1" ]] && help_message

### Execution variables ###

mlog=1
flat=0
func=""
lsaur=0
ptbin=0
agrmode=0
dry_run=0
do_snap=0
raw_cmd="$*"
log_lines=""
back_flags=()
final_args=()
only_flatpak=0

### Functions reload ###

log_rotate; detback; load_lang

[[ "$backend" == "pacman" && "$EUID" -ne 0 ]] && err "$E_07"
[[ "$backend" != "pacman" && "$EUID" -eq 0 ]] && err "$E_05"

### Flags testing ###

while [[ $# -gt 0 ]]; do
    case "$1" in
        --edit-config|updater|doctor|ra|--create-snapshot|dp|why|--ignore|pin|statsb|--pacdiff|--ping|--create-backup|--restore-backup|install|-i|remove|-r|update|-u|search|-s|query|-q|cache|-c|orphan|-o|mirrors|-m|slog|-cl|-sl|--fix-keys|--check-updates|--check-infected)
            [[ -z "$action" ]] && action="$1" || final_args+=("$1")
        ;;
        --testing)                 MODULES_FOLDER="./modules"; modules_test=1; load_modules ;;
        --debug)                   set -x ;;
        --dry-run)                 dry_run=1 ;;
        mksnap|--create-snapshot)  do_snap="1" ;;
        --list-aur|-ls-aur)        lsaur=1 ;;
        -fo|--flatpak-only)        only_flatpak=1 ;;
        --path-to-binary)          ptbin=1 ;;
        -nc|--noconfirm)           back_flags+=("--noconfirm") ;;
        -v|--version)              inform; exit 0 ;;
        -f|--flatpak)              flat=1 ;;
        --backend)                 shift; if [[ "$1" == "yay" || "$1" == "paru" ]]; then backend="$1"; else err "$E_04"; fi ;;
        -h|--help)                 help_message ;;
        --no-log)                  mlog=0 ;;
        --lines)                   shift; log_lines="$1" ;;
        --view)                    [[ -z "$action" ]] && action="--view" || final_args+=("$1") ;;
        --path)                    shift; [[ -z "$1" ]] && error "--path requires a file path argument"; custom_path="$1" ;;
        --info)                    inform; exit 0 ;;
        *)                         final_args+=("$1") ;;
    esac
    shift
done

[[ "$always_no_confirm" == "true" ]] && back_flags+=("--noconfirm")
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
    --edit-config)
        if [[ -n "$EDITOR" ]]; then $EDITOR "$CONFIG_FOLDER/config";
            elif command -v nano &>/dev/null; then nano "$CONFIG_FOLDER/config";
            elif command -v vi &>/dev/null; then vi "$CONFIG_FOLDER/config";
            elif command -v vim &>/dev/null; then vim "$CONFIG_FOLDER/config";
            elif command -v micro &>/dev/null; then micro "$CONFIG_FOLDER/config";
        else
            error "$M_EDITOR_NOT_FOUND"
            exit 1
        fi
        exit 0
    ;;
    --malware-check|--check-infected|aur-scanner|--aur-scanner) aur_scanner ;;
    -Rsn|-ra|--remove-agressive)                logback; agrmode=1; func="r"; proc_func ;;
    check-upds|--check-updates)                 check_updates ;;
    mksnap|--create-snapshot)                   mksnap; exit 0 ;;
    -Syu|-up|upd|update|-u)                     logback; func="u"; proc_func ;;
    -S|-in|ins|install|-i)                      logback; func="i"; proc_func ;;
    --clear-logs|clog|-cl)                      log_func="cl"; proc_log_func ;;
    -Ss|-sr|src|search|-s)                      logback; func="s"; proc_func ;;
    --stats|--statistics)                       show_stats ;;
    --show-logs|slog|-sl)                       log_func="sl"; proc_log_func ;;
    -rb|--restore-backup)                       backup_action="restore"; backup_func ;;
    -R|rem|remove|-r|-rm)                       logback; func="r"; proc_func ;;
    -Q|-qr|qur|query|-q)                        logback; func="q"; proc_func ;;
    -cb|--create-backup)                        backup_action="create"; backup_func ;;
    -mr|mir|mirrors|-m)                         refresh_mirrors ;;
    -op|orp|orphan|-o)                          logback; rmorps ;;
    -cc|cac|cache|-c)                           logback; chmgr ;;
    pin|--ignore)                               package_pinner ;;
    depends|why)                                depends ;;
    --fix-keys)                                 fix_keys ;;
    -vi|--view)                                 logback; view_pkgbuild "${final_args[0]}"; exit 0 ;;
    --pacdiff)                                  logback; ckconf ;;
    updater)                                    cly_updater ;;
    doctor)                                     doctor ;;
    --ping)                                     ping_cmd="1"; network_test; exit 0 ;;
    *)                                          err "$E_01 '$action'" ;;
esac

### Execution ###

if [[ "$dry_run" == "1" ]]; then
    echo -e "\n${YELLOW}$M_DRY_RUN_SIM${NC}"
    [[ -n "$cmd" ]] && echo -e "${CYAN}$M_DRY_RUN_RUN${NC} $backend $cmd ${final_args[*]} ${back_flags[*]}"
    [[ "$flat" == "1" && -n "$flat_cmd" ]] && echo -e "${CYAN}$M_DRY_RUN_RUN${NC} flatpak $flat_cmd ${final_args[*]}"
    echo -e "${GREEN}$M_DRY_RUN_NONE${NC}\n"
    exit 0
fi

if [[ -n "$cmd" ]]; then
    [[ "$func" != "s" ]] && log_type="2" && mklog "Executing $backend $cmd ${final_args[@]} ${back_flags[@]}"
    if [[ "$func" == "i" && "$MALWARE_CHECK" == "true" ]]; then
        echo " $CC $M_SEARCH_INFECTED"
        for pkg in "${final_args[@]}"; do
            grep -Exi "$pkg" "$MODULES_FOLDER/infected_packages.txt" &>/dev/null && {
                echo -e "${YELLOW} $ALERT $M_INFECTED_PKG_FOUND: $pkg"
                exit 1
            }
        done
    fi
    "$backend" "$cmd" "${final_args[@]}" "${back_flags[@]}" 2>&1 | tee "$tmp_out"
    exit_code=${PIPESTATUS[0]}
    rflat
fi

if [[ -n "$tag" ]]; then
    if [[ "$exit_code" -ne 0 ]]; then
        mklog "NOT FOUND" "${raw_cmd}"
    else
        mklog "${tag:-SYSTEM}" "${raw_cmd}"
    fi
fi

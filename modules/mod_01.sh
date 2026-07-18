#!/usr/bin/env bash

ntest() {
    st "$M_NET_TEST"
    ping -c 1 -i 0.2 8.8.8.8 &>/dev/null &
    local pid=$!
    local spin='-\|/'
    while kill -0 $pid 2>/dev/null; do
        local i=$(( (i+1)%4 ))
        printf "\r${CYAN} [%c] $M_WAITING...\033[K${NC}" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r\033[K"
    if wait $pid; then
        sc "$M_NET_OK"
        log_type="net" && mklog "Network test" "available"
    else
        echo -e "${RED}$ERROR \033[K${NC}$M_NET_ERR"
        log_type="net" && mklog "Network test" "unavailable"
        exit 1
    fi
}

proc_func() {
    tag="$action"
    case "$func" in
        i)
            ntest
            cmd="-S"
            flat_cmd="install"
            tag="install"
            tag_cmd="install"
            log_type="1" && mklog $action $tag_cmd
        ;;
        r)
            cmd=$([[ "$agrmode" == "1" ]] && echo "-Rsn" || echo "-Rs")
            tag="remove"
            [[ "$agrmode" == "1" ]] && echo -e "${RED} $NOTE $M_AGRESSIVE_MODE${NC}"
            flat_cmd="uninstall"
            tag_cmd="remove"
            log_type="1" && mklog $action $tag_cmd
        ;;
        u)
            ntest
            [[ "$do_snap" == "1" ]] && mksnap
            cmd="-Syu"
            flat_cmd="update"
            tag="update"
            tag_cmd="update"
            log_type="1" && mklog $action $tag_cmd
        ;;
        s)
            ntest
            cmd="-Ss"
            flat_cmd="search"
            tag="search"
            tag_cmd="search"
            log_type="1" && mklog $action $tag_cmd
        ;;
        q)
            cmd="-Qs"
            [[ "$lsaur" == 1 ]] && cmd="-Qqm"
            flat_cmd="list"
            tag="list"
            tag_cmd="query"
            log_type="1" && mklog $action $tag_cmd
            [[ "$ptbin" == 1 ]] && get_package_path "${final_args[@]}" && tag="SKIP" && return
        ;;
        *)
            err "var func not defined"
        ;;
    esac
}

dpver() { echo "cly $ver - release: $rc"; }

inform() {
    local version_padded
    printf -v version_padded "v%-6s" "$ver"
    
echo -e "${CYAN}${BOLD}         __      "     
echo -e "${CYAN}${BOLD}   _____/ /_  __ "
echo -e "${CYAN}${BOLD}  / ___/ / / / / "
echo -e "${CYAN}${BOLD} / /__/ / /_/ /  "
echo -e "${CYAN}${BOLD} \___/_/\__, /   "
echo -e "${CYAN}${BOLD}       /____/    "
    echo -e "\n ${YELLOW}$M_RELEASE ${CYAN}$rc\n ${YELLOW}$M_MADE_BY ${CYAN}xml.dev\n${GREEN} $M_THANKS\n ${NC}"
    exit 0
}

help_message() {
    echo "$H_USAGE: cly [$USG1] [$USG2] [$USG3]"
    echo "$H_USAGE: cly [-i | -r | -s | -u | check] [-f | --flatpak] [--noconfirm]"
    echo "$H_USAGE: cly [-q | query] [--list-aur] [--path-to-binary]"
    echo "$H_USAGE: cly [--restore-backup] [--path /path/to/backup/file.txt]"
    echo "$H_USAGE: cly [--backend] [yay | paru]"
    echo "$H_USAGE: cly [slog|-sl] [--lines X]"
    echo -e "\n$H_OPTIONS:\n"
    echo "-h, --help               $H_HELP"
    echo "-v, --version            $H_VERSION"
    echo "-i, install              $H_INSTALL"
    echo "-r, remove               $H_REMOVE"
    echo "-u, update               $H_UPDATE"
    echo "-s, search               $H_SEARCH"
    echo "-q, query                $H_QUERY"
    echo "-o, orphan               $H_ORPHAN"
    echo "-c, cache                $H_CACHE"
    echo "-m, mirrors              $H_MIRRORS"
    echo "dp, why                  $H_WHY"
    echo "snap, --create-snapshot  $H_SNAP"
    echo "pin, --ignore            $H_PIN"
    echo "--check-updates          $H_CHECK_UPD"
    echo "--info                   $H_INFO"
    echo "--fix-keys               $H_FIX_KEYS"
    echo "--pacdiff                $H_PACDIFF"
    echo "--create-backup          $H_CREATE_BKp"
    echo "--restore-backup         $H_RESTORE_BKp"
    echo "--path-to-binary         $H_PATH_BIN"
    echo "--ping                   $H_PING"
    echo "--view                   $H_VIEW"
    echo "--no-log                 $H_NO_LOG"
    echo "--dry-run                $H_DRY"
    echo "--statistics, stats      $H_STATS"
    echo "--flatpak-only           $H_FLAT_ONLY"
    echo -e "--backend             $H_BACKEND\n"
    dpver
    exit 0
}

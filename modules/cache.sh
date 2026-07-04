#!/usr/bin/env bash

chmgr() {
    log_type="1" && mklog "-Sc" "clean-cache"
    local cache_dir="$REAL_HOME/.cache/$backend"
    if [[ -d "$cache_dir" ]]; then
        st "$M_CACHE_CLEANING_BUILDS"
        find "$cache_dir" -maxdepth 1 -type d -not -path "$cache_dir" -exec rm -rf {} +
        sc "$M_CACHE_BUILDS_CLEANED"
    fi
    if command -v flatpak &>/dev/null; then
        st "$M_CACHE_CLEANING_FLATPAK"
        flatpak uninstall --unused -y &>/dev/null
        sc "$M_CACHE_FLATPAK_CLEANED"
    fi
    st "$M_CACHE_CLEANING_PACMAN"
    cmd="-Sc"
    tag="Wiped cache"
}

rmorps() {
    log_type="1" && mklog "-Qtqd" "remove-orphans"
    st "$M_ORPHANS_SEARCHING"
    mapfile -t final_args < <("$backend" -Qqtd 2>/dev/null)
    orphans_n=${#final_args[@]}
    [[ "$orphans_n" -eq 0 ]] && { sc "$M_ORPHANS_NONE"; mklog "SEARCHED ORPHANS" "clean"; exit 0; }
    echo "$NOTE $orphans_n $M_ORPHANS_FOUND"
    printf '%s\n' "${final_args[@]}"
    st "$M_ORPHANS_REMOVING"
    cmd="-Rsn"
    tag="REMOVED ORPHANS"
}

ckconf() {
    log_type="1" && mklog "pacnews" "conf-merge" "0"
    st "$M_CONF_SEARCHING"
    local pacnews=$(find /etc -regextype posix-extended -regex ".+\.pac(new|save)" 2>/dev/null)
    if [[ -z "$pacnews" ]]; then sc "$M_CONF_NONE"; else
        echo -e "${YELLOW} $NOTE $M_CONF_PENDING${NC}"
        echo "$pacnews"
        echo -e "\n${CYAN} $CC ${NC}$M_CONF_MERGE_PROMPT"
        read -r -n 1 opt
        echo
        [[ "$opt" =~ ^[yYsS]$ ]] && sudo pacdiff
    fi
    tag="CLEAR DIFFS"
}
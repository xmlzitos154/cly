#!/usr/bin/env bash

### Cache manager ###

chmgr() {
    log_type="1" && mklog "-Sc" "clean-cache"
    local cache_dir="$REAL_HOME/.cache/$backend"
    if [[ -d "$cache_dir" ]]; then
        st "$M_CACHE_CLEANING_BUILDS"
        rm -rf "${cache_dir:?}"/*/
        sc "$M_CACHE_BUILDS_CLEANED"
    fi
    if [[ "$flat" == "1" ]]; then
        if command -v flatpak &>/dev/null; then
            st "$M_CACHE_CLEANING_FLATPAK"
            flatpak uninstall --unused -y &>/dev/null
            sc "$M_CACHE_FLATPAK_CLEANED"
        fi
    fi
    st "$M_CACHE_CLEANING_PACMAN"
    cmd="-Sc"
    tag="Wiped cache"
}

### Orphans remover ###

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

### Pacdiff/pacnew manager ###

ckconf() {
    log_type="1" && mklog "pacnews" "conf-merge" "0"
    st "$M_CONF_SEARCHING"
    local pacnews; pacnews=$(find /etc -regextype posix-extended -regex ".+\.pac(new|save)" 2>/dev/null)
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

### AUR Infected packages scanner ###

aur_scanner() {
    [[ ! -f "$MODULES_FOLDER/infected_packages.txt" ]] && err "$E_SCAN_NO_LIST"
    local tmp_found; tmp_found=$(mktemp)
    local spin='-\|/'
    local i=0

    (
        while IFS= read -r pkg; do
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            if [[ "$backend" != "pacman" ]]; then
                "$backend" -Qqs 2>/dev/null | grep -qx "$pkg" && echo "$pkg" >> "$tmp_found"
            else
                pacman -Qqm "$pkg" &>/dev/null && echo "$pkg" >> "$tmp_found"
            fi
        done < "$MODULES_FOLDER/infected_packages.txt"
    ) &
    local pid=$!

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1)%4 ))
        printf "\r${CYAN} [%c] $M_SCANNING...\033[K${NC}" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r\033[K"
    wait $pid

    local found=()
    while IFS= read -r line; do
        found+=("$line")
    done < "$tmp_found"
    rm -f "$tmp_found"

    if [[ ${#found[@]} -gt 0 ]]; then
        echo -e "${RED} $ALERT $M_SCAN_FOUND${NC}"
        printf '  %s\n' "${found[@]}"
        echo -e "${YELLOW} $NOTE $M_SCAN_REMOVE ${found[*]}${NC}"
    else
        sc "$M_SCAN_CLEAN"
    fi
    mklog "SCAN" "${#found[@]} $M_SCAN_LOG"
}

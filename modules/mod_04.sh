#!/usr/bin/env bash

mksnap() {
    log_type="1" && mklog "timeshift" "System snapshot" "0"
    st "$M_SNAP_CHECK"
    if command -v timeshift &>/dev/null; then
        st "$M_SNAP_CREATING"
        if sudo timeshift --create --comments "CLY Auto-Snapshot before update" --tags D; then
            sc "$M_SNAP_sc"
        else
            echo -e "${YELLOW} $NOTE Warning: Snapshot backup failed, but continuing update...${NC}"
        fi
    else
        echo -e "${YELLOW} $NOTE $M_SNAP_NOT_FOUND${NC}"
    fi
}

pin() {
    log_type="1" && mklog "pin" "pin a package" "0"
    local pkg="${final_args[0]}"
    local conf="/etc/pacman.conf"
    [[ -z "$pkg" ]] && error "$M_DEPS_SPECIFY"
    ! pacman -Qi "$pkg" &>/dev/null && err "$M_DEPS_NOT_FOUND '$pkg'"
    local current
    current=$(grep -oP '(?<=^IgnorePkg = ).*' "$conf")
    if echo "$current" | grep -qw "$pkg"; then
        local new
        new=$(echo "$current" | sed "s/\b$pkg\b//" | tr -s ' ' | sed 's/^ //;s/ $//')
        sudo sed -i "s/^IgnorePkg = .*/IgnorePkg = $new/" "$conf"
        sc "$pkg unpinned."
        mklog "Unpin" "$pkg"
    elif grep -q "^IgnorePkg" "$conf";
    then
        sudo sed -i "s/^IgnorePkg = .*/IgnorePkg = $current $pkg/" "$conf"
        sc "$pkg pinned."
        mklog "Pin" "$pkg"
    elif grep -q "^#IgnorePkg" "$conf";
    then
        sudo sed -i "s/^#IgnorePkg.*/IgnorePkg = $pkg/" "$conf"
        sc "$pkg pinned."
        mklog "Pin" "$pkg"
    else
        sudo sed -i "/^\[options\]/a IgnorePkg = $pkg" "$conf"
        sc "$pkg pinned."
        mklog "Pin" "$pkg"
    fi
}

depends() {
    log_type="1" && mklog "pactree" "Check for dependencies" "0"
    ! command -v pactree &>/dev/null && { st "$M_INSTALL_CONTRIB pacman-contrib..."; "$backend" -S pacman-contrib --noconfirm; }
    local pkg="${final_args[0]}"
    [[ -z "$pkg" ]] && echo "$ALERT $M_DEPS_SPECIFY" && exit 1
    ! pacman -Qi "$pkg" &>/dev/null && echo -e "$ERROR ${YELLOW}$M_DEPS_NOT_FOUND '$pkg'" && exit 1
    st "$M_DEPS_CHECKING '$pkg'..."
    local deps_n
    local deps
    deps=$(pactree -r "$pkg" 2>/dev/null | tail -n +2)
    deps_n=$(echo "$deps" | wc -l)
    if [[ -z "$deps" ]];
    then
        sc "$M_DEPS_NONE $pkg."
        mklog "WHY" "$pkg -> No dependencies"
        exit 0
    fi
    echo -e "\n $NOTE $deps_n $M_DEPS_FOUND_COUNT"
    echo -e "${YELLOW} $CC '$pkg' $M_DEPS_REQUIRED_BY${NC}"
    echo "$deps" | sed 's/^/  /'
    echo -e "\n${CYAN} $NOTE $M_DEPS_SUGGESTED_ORDER${NC}"
    local pkgs
    pkgs=$(echo "$deps" | grep -oP '[\w][\w.+@-]+' | awk '!seen[$0]++' | tr '\n' ' ')
    echo "  cly -r $pkgs"
    mklog "WHY" "$pkg"
}

show_stats() {
    st "$M_STATS_GATHERING"
    local native_pkgs; native_pkgs=$(pacman -Qn | wc -l)
    local aur_pkgs; aur_pkgs=$(pacman -Qm | wc -l)
    local flat_pkgs=0
    if command -v flatpak &>/dev/null;
    then
        flat_pkgs=$(flatpak list --app | wc -l)
    fi
    local cache_size; cache_size=$(du -sh /var/lib/pacman | cut -f1)
    local install_date; install_date=$(head -n1 /var/log/pacman.log | cut -d' ' -f1 | tr -d '[]' | cut -d'T' -f1)
    local aur_cache_size="0"
    [[ -d "$REAL_HOME/.cache/$backend" ]] && aur_cache_size=$(du -sh "$REAL_HOME/.cache/$backend" | cut -f1)
    echo -e "\n${YELLOW}$M_STATS_TITLE${NC}"
    echo -e "${GREEN}$M_STATS_PACKAGES${NC}"
    echo "  $CC $M_STATS_NATIVE $native_pkgs"
    echo "  $CC AUR:    $aur_pkgs"
    [[ $flat_pkgs -gt 0 ]] && echo "  $CC Flatpak: $flat_pkgs"
    echo -e "\n${CYAN}$M_STATS_DISK_USAGE${NC}"
    echo "  $CC $M_STATS_PACMAN_DB $cache_size"
    echo "  $CC $M_STATS_BORN_ON $install_date"
    echo "  $CC $backend Cache: $aur_cache_size"
    if command -v expac &>/dev/null;
    then
        echo -e "\n${YELLOW}$M_STATS_HEAVIEST${NC}"
        expac "%m %n" | sort -rn | head -10 | awk '{printf "  %s MB\t%s\n", $1/1024/1024, $2}'
    else
        echo -e "\n${YELLOW}$NOTE $M_STATS_EXPAC_WARN${NC}"
    fi
    echo -e "${CYAN}------------------------${NC}"
    tag="STATS"
}

view_pkgbuild() {
    log_type="1" && mklog "-Gp" "View PKGBUILD file"
    [[ "$backend" == "pacman" ]] && err "$E_08"
    local pkg="$1"
    [[ -z $pkg ]] && echo "$NOTE $M_PKGB_SPECIFY" && exit 1
    st "$M_PKGB_SEARCHING $pkg..."
    local content
    content=$("$backend" -Gp "$pkg" 2>/dev/null)
    if [[ -n "$content" ]];
    then
        echo -e "${CYAN}--- PKGBUILD: $pkg ---${NC}\n"
        echo "$content" | less -R
        tag="VIEW PKGBUILD"
    else
        error "$M_PKGB_NOT_FOUND '$pkg'. $M_PKGB_AUR_QUESTION"
    fi
}

refresh_mirrors() {
    ntest
    log_type="1" && mklog "reflector" "Refresh mirrors"
    st "$M_MIRROR_START"
    if ! command -v reflector &>/dev/null; then
        echo -e "${YELLOW}$NOTE $M_REFLECTOR_NOT_FOUND${NC}"
        read -p "$M_INSTALL_REFLECTOR_PROMPT" -n 1 -r
        if [[ "$REPLY" =~ ^[YySs]$ || -z "$REPLY" ]]; then
            echo
            sudo pacman -S reflector --noconfirm
        else
            echo
            error "$M_REFLECTOR_REQUIRED"
        fi
    fi
    mirror_country="$(curl -s --max-time 2 https://ipinfo.io/country 2>/dev/null)"
    reflector_args=(--latest 20 --protocol https --sort rate)
    if [[ -n "$mirror_country" ]]; then
        st "$M_USING_MIRRORS_FROM $mirror_country"
        reflector_args+=(--country "$mirror_country")
    else
        st "$M_NO_COUNTRY_WORLDWIDE"
    fi
    
    st "$M_MIRROR_BACKUP"
    sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    st "$M_FETCHING_MIRRORS"
    
    if sudo reflector "${reflector_args[@]}" --save /etc/pacman.d/mirrorlist; then
        sc "$M_MIRRORS_sc"
        tag="Mirrors refresh"
    else
        error "$M_MIRRORS_FAILED"
    fi
}

fix_keys() {
    log_type="1" && mklog "gpg" "Recovery gpg keys"
    st "$M_GPG_START"
    if ! $backend -Qs archlinux-keyring; then "$backend" -S archlinux-keyring --noconfirm --needed 2>&1 | tee "$tmp_out"; fi
    if [[ -f "$tmp_out" ]]; then
        local keys=$(grep -oP '(?<=key\s)([A-F0-9]{16,})|(?<=ID\s)([A-F0-9]{16,})' "$tmp_out" | sort -u)
        if [[ -n "$keys" ]]; then
            for key in $keys; do
                st "$M_IMPORTING_KEY $key"
                gpg --recv-keys "$key" || gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key"
            done
        fi
    fi
    st "$M_CLEANING_KEY_CACHE"
    sudo find /etc/pacman.d/gnupg -type f -name "*.lck" -delete
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sc "$M_DONE"
}

backup_func() {
    log_type="1" && mklog "backup" "Create / restore backups" "0"
    case "$backup_action" in
        "create")
            st "Creating backup of packages..."
            mkdir -p "$BACKUP_DIR"
            "$backend" -Qqa > "$BACKUP_FILE"
            checksum=$(sha256sum "$BACKUP_FILE" | cut -d' ' -f1)
            echo "$checksum" > "$BACKUP_DIR/backup.sha256"
            sc "Backup created successfully in $BACKUP_FILE"
            mklog "CREATED BACKUP" "$BACKUP_FILE"
            exit 0
        ;;
        "restore")
            [[ -n "$custom_path" ]] && BACKUP_FILE="$custom_path"
            if [[ ! -f "$BACKUP_FILE" ]]; then
                error "Backup file not found."
            fi
            local backup_base="${BACKUP_FILE%.*}"
            checksum_file="${backup_base}.sha256"
            if [[ ! -f "$checksum_file" ]]; then
                error "Validation key not found. Backup may be invalid or corrupted."
            fi
            st "Validating backup integrity..."
            local stored_hash
            stored_hash=$(cat "$checksum_file")
            local actual_hash
            actual_hash=$(sha256sum "$BACKUP_FILE" | cut -d' ' -f1)
            if [[ "$stored_hash" != "$actual_hash" ]]; then
                error "Backup validation failed. File may be corrupted or tampered."
            fi
            sc "Backup integrity verified."
            st "Restoring backup..."
            mapfile -t pkg_list < "$BACKUP_FILE"
            if "$backend" -S "${pkg_list[@]}" --needed; then
                sc "Backup restored."
                mklog "BACKUP RESTORATION" "Reinstalled ${#pkg_list[@]} packages"
                exit 0
            else
                error "Restore failed."
            fi
        ;;
    esac
}

check_updates() {
    ntest
    log_type="1" && mklog "-Qua" "Search for updates"
    [[ "$backend" == "pacman" ]] && return 0
    if "$backend" -Qua 2>/dev/null | grep -qi "cly"; then
        echo -e "$M_CLY_UPD_FOUND"
    fi
    ! command -v checkupdates &>/dev/null && { st "$M_INSTALL_DEPS"; "$backend" -S pacman-contrib --noconfirm; }
    st "$M_SEARCHING_UPDATES"
    local tmp_repo=$(mktemp)
    local tmp_aur=$(mktemp)
    checkupdates > "$tmp_repo" 2>/dev/null &
    local pid_repo=$!
    local pid_aur=""
    if [[ "$backend" == "pacman" ]]; then
        touch "$tmp_aur"
    else
        "$backend" -Qua > "$tmp_aur" 2>/dev/null &
        pid_aur=$!
    fi
    local pid_flat=""
    local tmp_flat=""
    if [[ "$flat" == "1" ]] && command -v flatpak &>/dev/null; then
        tmp_flat=$(mktemp)
        flatpak remote-ls --updates > "$tmp_flat" 2>/dev/null &
        pid_flat=$!
    fi
    wait $pid_repo ${pid_aur:+$pid_aur} ${pid_flat:+$pid_flat}
    local upds_n=$(wc -l < "$tmp_repo")
    local upds_aur_n=$(wc -l < "$tmp_aur")
    local upds_flat_n=0
    [[ -f "$tmp_flat" ]] && upds_flat_n=$(wc -l < "$tmp_flat")
    local total=$((upds_n + upds_aur_n + upds_flat_n))
    if [[ "$total" -eq 0 ]]; then
        sc "$M_SYSTEM_UPDATE"
        rm -f "$tmp_repo" "$tmp_aur" ${tmp_flat:+"$tmp_flat"}
        return
    fi
    local flat_info=""
    [[ "$flat" == "1" ]] && flat_info=" $M_AND $upds_flat_n $M_IN_FLATPAK"
    echo -e "${YELLOW} $NOTE $total $M_UPDATES_FOUND ($upds_aur_n $M_IN_AUR$flat_info):${NC}"
    [[ "$upds_n" -gt 0 ]] && echo -e "\n$M_OFFICIAL_UPDATES\n${CYAN}$(cat "$tmp_repo")${NC}"
    [[ "$upds_aur_n" -gt 0 ]] && echo -e "\n$M_AUR_UPDATES\n${GREEN}$(cat "$tmp_aur")${NC}"
    if [[ "$flat" == "1" && "$upds_flat_n" -gt 0 ]]; then
        echo -e "\n$M_FLATPAK_UPDATES\n${YELLOW}$(cat "$tmp_flat")${NC}"
    fi
    rm -f "$tmp_repo" "$tmp_aur" ${tmp_flat:+"$tmp_flat"}
    mklog "FOUND UPDATES" "$total updates (Flatpak: $flat)"
}

get_package_path() {
    log_type="1" && mklog "-Ql" "get package path"
    local pkg="$1"
    local bins=$(pacman -Ql "$pkg" 2>/dev/null | awk '/\/bin\// {print $2}')
    if [[ -n "$bins" ]]; then
        echo -e "${GREEN}Binaries found:${NC}\n$bins"
    else
        st "No binaries found in $pkg"
    fi
}

doctor() {
    local issues=0
    echo -e "\n${BOLD}${CYAN}:: $M_DOCTOR_SYSTEM${NC}"
    
    local kernel; kernel=$(uname -r)
    st "Kernel: $kernel"
    
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo -e " ${RED}$ERROR${NC} Pacman lock detectado — rode: sudo rm /var/lib/pacman/db.lck"
        ((issues++))
    else
        sc "$M_DOCTOR_NO_LOCK"
    fi
    
    local outdated; outdated=$(checkupdates 2>/dev/null | wc -l)
    if [[ "$outdated" -gt 0 ]]; then
        echo -e " ${YELLOW}$NOTE${NC} $outdated $M_DOCTOR_OUTDATED — cly -u"
        ((issues++))
    else
        sc "$M_DOCTOR_UP_TO_DATE"
    fi
    
    local orphans; orphans=$("$backend" -Qqtd 2>/dev/null | wc -l)
    if [[ "$orphans" -gt 0 ]]; then
        echo -e " ${YELLOW}$NOTE${NC} $orphans $M_DOCTOR_ORPHANS — cly -o"
        ((issues++))
    else
        sc "$M_DOCTOR_NO_ORPHANS"
    fi
    
    echo -e "\n${BOLD}${CYAN}:: $M_DOCTOR_STORAGE${NC}"
    
    local pac_cache; pac_cache=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
    local pac_cache_mb; pac_cache_mb=$(du -sm /var/cache/pacman/pkg 2>/dev/null | cut -f1)
    if [[ "$pac_cache_mb" -gt 1024 ]]; then
        echo -e " ${YELLOW}$NOTE${NC} $M_DOCTOR_PAC_CACHE $pac_cache — cly -c"
        ((issues++))
    else
        sc "$M_DOCTOR_PAC_CACHE $pac_cache"
    fi
    
    local aur_cache_dir="$REAL_HOME/.cache/$backend"
    if [[ -d "$aur_cache_dir" ]]; then
        local aur_cache; aur_cache=$(du -sh "$aur_cache_dir" 2>/dev/null | cut -f1)
        local aur_cache_mb; aur_cache_mb=$(du -sm "$aur_cache_dir" 2>/dev/null | cut -f1)
        if [[ "$aur_cache_mb" -gt 512 ]]; then
            echo -e " ${YELLOW}$NOTE${NC} $M_DOCTOR_AUR_CACHE $aur_cache — cly -c"
            ((issues++))
        else
            sc "$M_DOCTOR_AUR_CACHE $aur_cache"
        fi
    fi
    
    local log_size; log_size=$(du -sh "$LOG_FILE" 2>/dev/null | cut -f1)
    sc "$M_DOCTOR_LOG $log_size"
    
    echo -e "\n${BOLD}${CYAN}:: $M_DOCTOR_NETWORK${NC}"
    
    if ping -c 1 -i 0.2 8.8.8.8 &>/dev/null; then
        sc "$M_NET_OK"
    else
        echo -e " ${RED}$ERROR${NC} $M_NET_ERR"
        ((issues++))
    fi
    
    if command -v reflector &>/dev/null; then
        local mirror_age; mirror_age=$(stat -c %Y /etc/pacman.d/mirrorlist 2>/dev/null)
        local now; now=$(date +%s)
        local diff=$(( (now - mirror_age) / 86400 ))
        if [[ "$diff" -gt 30 ]]; then
            echo -e " ${YELLOW}$NOTE${NC} $M_DOCTOR_MIRRORS ${diff}d — cly -m"
            ((issues++))
        else
            sc "$M_DOCTOR_MIRRORS_OK"
        fi
    fi
    
    echo ""
    if [[ "$issues" -eq 0 ]]; then
        echo -e "${GREEN}${BOLD} $COMPLETE $M_DOCTOR_ALL_GOOD${NC}\n"
    else
        echo -e "${YELLOW}${BOLD} $NOTE $issues $M_DOCTOR_ISSUES${NC}\n"
    fi
    
    tag="DOCTOR"
    mklog "DOCTOR" "system check - $issues issues"
}

cly_updater() {
    ntest
    echo -e "${CC} ${M_UPDATING_CLY}..."
    if $backend -Syu cly; then
        echo '${GREEN}${COMPLETE} Done.'
    fi
}
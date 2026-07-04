#!/usr/bin/env bash

rflat() {
    [[ "$flat" != "1" ]] && return
    command -v flatpak &>/dev/null || err "$E_06"
    if [[ "$dry_run" == "1" ]]; then
        echo -e "\n${YELLOW}$M_DRY_FLATPAK${NC}"
        echo -e "${CYAN}$M_DRY_RUN_RUN${NC} flatpak $flat_cmd ${final_args[*]}"
        echo -e "${GREEN}$M_DRY_RUN_NONE${NC}\n"
        exit 0
    fi
    case "$action" in
        update|-u)
            st "$M_FLAT_UPDATING"
            flatpak update -y 2>&1 | tee -a "$tmp_out"
            flat_exit=${PIPESTATUS[0]}
            exit_code=$flat_exit
        ;;
        search|-s)
            st "$M_FLAT_SEARCHING"
            flatpak "$flat_cmd" "${final_args[@]}"
        ;;
        *)
            flatpak "$flat_cmd" -y "${final_args[@]}"
            flat_exit=$?
            [[ $flat_exit -eq 0 ]] && tag="$tag + FLATPAK" || tag="$tag (flatpak failed)"
        ;;
    esac
}

flatpak_only() {
    ! command -v flatpak &>/dev/null && err "$E_06"
    echo -e "${BOLD}${GREEN} $CC $M_USING_FLATPAK${NC}"
    case "$action" in
        -in|ins|install|-i)       flat_cmd="install" ;;
        rem|remove|-r|-rm)        flat_cmd="uninstall" ;;
        -up|upd|update|-u)        flat_cmd="update" ;;
        -sr|src|search|-s)        flat_cmd="search" ;;
        -qr|qur|query|-q)         flat_cmd="list" ;;
        -cc|cac|cache|-c)         flat_cmd="uninstall --unused" ;;
        --check-upds|--check-updates) flat_cmd="remote-ls --updates" ;;
        *) error "$M_FLAT_NOT_SUP" ;;
    esac
    if [[ "$dry_run" == "1" ]]; then
        echo -e "\n${YELLOW}$M_DRY_FLATPAK${NC}"
        echo -e "${CYAN}$M_DRY_RUN_RUN${NC} flatpak $flat_cmd ${final_args[*]}"
        echo -e "${GREEN}$M_DRY_RUN_NONE${NC}\n"
        exit 0
    fi
    log_type="1" && mklog "flatpak $flat_cmd ${final_args[*]}" "flatpak-only" "0"
    flatpak $flat_cmd "${final_args[@]}"
    exit_code=$?
    tag="FLATPAK ONLY"
    printf -v date_str '%(%Y-%m-%d - %H:%M:%S)T' -1
    echo "[$date_str] $tag -> flatpak $flat_cmd ${final_args[*]}; flatpak=true - Exit Status $exit_code" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
    exit $exit_code
}
#!/usr/bin/env bash

log_rotate() {
    local max_size=128000
    local log_size
    log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    [[ "$log_size" -lt "$max_size" ]] && return
    local log_size_hr
    log_size_hr=$(du -sh "$LOG_FILE" | cut -f1)
    echo -e "\n${YELLOW} $NOTE $M_LARGE_LOG_FILE ($log_size_hr).${NC}"
    echo -e -n "${CYAN} $CC ${NC}$ASK_ROTATE? [$ASK_1/$ASK_2]"
    read -r -n 1 opt
    echo
    if [[ "$opt" =~ ^(y|Y|s|S)$ ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.1"
        touch "$LOG_FILE"
        sc "$M_ROTATED cly.log.1"
    fi
}

mklog() {
    [[ "$mlog" == 0 ]] && return 0
    printf -v date_str '%(%Y-%m-%d - %H:%M:%S)T' -1
    
    if [[ "$log_type" == "1" ]]; then
        local info1="$1"
        local info2="$2"
        [[ "$3" == "0" ]] && prback="" || prback="with $backend..."
        echo "[$date_str] Executing $info1 [$info2] $prback" >> "$LOG_FILE"
        log_type=0
        return
    fi
    
    if [[ "$log_type" == "2" ]]; then
        echo "[$date_str] $1" >> "$LOG_FILE"
        log_type=0
        return
    fi
    
    if [[ "$log_type" == "net" ]]; then
        info1="$1"
        info2="$2"
        log_type="0"
        echo "[$date_str] $1 -> $2" >> "$LOG_FILE"
        return
    fi
    
    local status="${exit_code:-0}"
    local tag="$1"
    local cmd_str
    if [[ -n "$cmd" ]]; then
        cmd_str="$backend $cmd"
    else
        cmd_str="flatpak $flat_cmd"
    fi
    [[ ${#final_args[@]} -gt 0 ]] && cmd_str+=" ${final_args[*]}"
    [[ ${#back_flags[@]} -gt 0 ]] && cmd_str+=" ${back_flags[*]}"
    local used_flat=$([[ "$flat" == "1" ]] && echo "true" || echo "false")
    echo "[$date_str] $tag -> $cmd_str - flatpak = $used_flat - Exit Status $status" >> "$LOG_FILE"
    echo " " >> "$LOG_FILE"
}

proc_log_func() {
    case "$log_func" in
        sl)
            [[ ! -s "$LOG_FILE" ]] && echo -e "${YELLOW}$NOTE $M_EMPTY_LOG" && exit 0
            if [[ -n "$log_lines" && "$log_lines" =~ ^[0-9]+$ ]]; then
                tail -n "$log_lines" "$LOG_FILE"
                exit 0
            else
                cat "$LOG_FILE"
                exit 0
            fi
        ;;
        cl)
            [[ ! -s "$LOG_FILE" ]] && echo "$NOTE $M_EMPTY_LOG" && exit 0
            : > "$LOG_FILE"
            sc "$M_DONE"
            exit 0
        ;;
        *)
            err "logging var not defined."   
        ;;
    esac
}
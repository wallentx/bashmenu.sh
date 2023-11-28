#!/usr/bin/env bash

if [[ "$(basename "$0")" == "bashmenu.sh" ]]; then
DESCRIPTION=$(cat <<- EOF
####################### DESCRIPTION: #######################
#
# bashmenu.sh is a script providing single, and multi-
# selection menu functionalities in bash.
# It is designed to be sourced into other scripts, not
# executed directly.
#
# The script offers two main functions: 'singleselect', and
# 'multiselect'.
# Both functions have specific positional arguments:
#
# $1. Display Legend Flag (string):
#       "true" to display navigation instructions, any other
#       value to hide them.
# $2. Result Variable Name (string):
#       The name of the variable where the result will be
#       stored (as an array).
# $3. Options (array):
#       An array of strings representing the menu options.
# $4. Default Selection:
#       - For multiselect:
#         An array of booleans (true/false) indicating
#         preselected ([✔]) options.
#       - For singleselect:
#         An integer representing the index of the default
#         selected option.
#
########################## USAGE: ##########################
#
# Navigation Controls:
#   ↓ (Down Arrow) => Move cursor down
#   ↑ (Up Arrow)   => Move cursor up
#   ⎵ (Space)      => Toggle selection (for multiselect)
#                     Make selection (for singleselect)
#   ⏎ (Enter)      => Confirm selection
#
######################### EXAMPLE: #########################
#
# source <(curl -sL bashmenu.sh)
#
# my_options=("Option 1" "Option 2" "Option 3")
#
# For multiselect:
# preselection=("true" "false" "false") # This can be blank
# multiselect "true" result my_options preselection
#
# For singleselect:
# singleselect "true" result my_options 0
# # 0 is the index of the default selected option
#
# Display the result:
# idx=0
# for option in "${my_options[@]}"; do
#     echo -e "$option\t=> ${result[idx]}"
#     ((idx++))
# done
#
############################################################
# The multiselect function was based on multiselect.miu.io
############################################################
EOF
)
    echo "$DESCRIPTION"
    exit 1
fi


# Helper functions
cursor_blink_on() { printf "\033[?25h"; }
cursor_blink_off() { printf "\033[?25l"; }
cursor_to() { printf "\033[%s;%sH" "$1" "${2:-1}"; }
print_inactive() {
    local formatted_option
    local formatted_prefix="$2"
    if [[ "$2" == *"✔"* ]]; then
        printf -v formatted_prefix "[\033[38;5;46m✔\033[0m]"
    fi
    printf -v formatted_option "\033[0m%s" "$1"
    printf "%s\t%s" "$formatted_prefix" "$formatted_option"
}
print_active() {
    local formatted_option
    local formatted_prefix="$2"
    # Check if the prefix contains the green checkmark and format accordingly
    if [[ "$2" == *"✔"* ]]; then
        printf -v formatted_prefix "[\033[38;5;46m✔\033[0m]"
    fi
    printf -v formatted_option "\033[7m%s\033[27m" "$1"
    printf "%s\t%s" "$formatted_prefix" "$formatted_option"
}
get_cursor_row() {
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    echo "${ROW#*[}"
}
key_input() {
    local key
    IFS= read -rsn1 key 2> /dev/null >&2
    case $key in
    "") echo enter ;;
    $'\x20') echo space ;;
    $'\x1b')
        read -rsn2 -t 0.1 key 2> /dev/null >&2
        case $key in
        "[A") echo up ;;
        "[B") echo down ;;
        esac
        ;;
    esac
}

display_legend() {
    if [[ $1 = "true" ]]; then
        echo -e "↓ (Down Arrow)\t=> down"
        echo -e "↑ (Up Arrow)\t=> up"
        echo -e "⎵ (Space)\t=> toggle selection"
        echo -e "⏎ (Enter)\t=> confirm selection"
        echo
    fi
}

multiselect() {
    local display_legend_flag=$1
    local return_value=$2
    local -n options=$3
    local -n defaults=$4
    local selected=()

    display_legend "$display_legend_flag"
    for ((i = 0; i < ${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - ${#options[@]}))
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    toggle_option() {
        local option=$1
        [[ ${selected[option]} == true ]] && selected[option]=false || selected[option]=true
    }

print_options() {
    local idx=0
    for option in "${options[@]}"; do
        local prefix="[ ]"
        if [[ ${selected[idx]} == true ]]; then
            prefix="[✔]"
        fi
        cursor_to "$((startrow + idx))"
        if [ "$idx" -eq "$1" ]; then
            print_active "$option" "$prefix"
        else
            print_inactive "$option" "$prefix"
        fi
        ((idx++))
    done
}

    local active=0
    while true; do
        print_options "$active"
        case $(key_input) in
        space) toggle_option "$active" ;;
        enter)
            print_options -1
            break
            ;;
        up)
            ((active--))
            ((active < 0)) && active=$(( ${#options[@]} - 1 ))
            ;;
        down)
            ((active++))
            ((active >= ${#options[@]})) && active=0
            ;;
        esac
    done
set +x
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on
    eval "$return_value"='("${selected[@]}")'
}

singleselect() {
    local display_legend_flag=$1
    local return_value=$2
    local -n options=$3
    local default_selection="${4:-0}"
    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - ${#options[@]}))

    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2

    display_legend "$display_legend_flag"
    cursor_blink_off
    for ((i = 0; i < ${#options[@]}; i++)); do
        printf "\n"
    done

    print_options() {
        local idx=0
        for option in "${options[@]}"; do
            local prefix=" ⬤ "
            [[ $idx -eq $selected ]] && prefix=" ◯ "
            cursor_to "$((startrow + idx))"
            if [ "$idx" -eq "$active" ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    local selected=$default_selection
    local active=0
    while true; do
        print_options "$active"
        case $(key_input) in
        space)
            if [ "$active" -eq "$selected" ]; then
                selected=-1
            else
                selected=$active
            fi
            ;;
        enter)
            local active=-1
            print_options "$active"
            break
            ;;
        up)
            ((active--))
            ((active < 0)) && active=$(( ${#options[@]} - 1 ))
            ;;
        down)
            ((active++))
            ((active >= ${#options[@]})) && active=0
            ;;
        esac
    done

    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    if [ "$selected" -eq -1 ]; then
        eval "$return_value"='("")'
    else
        eval "$return_value"='"${options[$selected]}"'
    fi
}

# ask to user is confirm, boolean function
# confirm_dialog "[y]/n" // "y" or no input is true
# confirm_dialog "yes/[no]" // only "yes" is true
confirm_dialog() {
    opts="${1:-y/n}"
    msg="${2:-Want to continue?}"
    selected="`select_dialog "$opts" "$msg"`"
    echo "$opts" | grep -qP "^\[?$selected[/,;\|\[\]]"
}

# show a list let user select, echo the selected, will be re-show dialog until input is valid
# eg. select_dialog "y/n" // re-show dialog if no type in
# eg. select_dialog "1,[2],3" // "2" will be selected if no type in
# eg. select_dialog "a|b|[c]" // "c" will be selected if no type in
# eg. select_dialog "a|b|[c]" "Select something, c is the default" // custom the note message
select_dialog() {
    opts="${1:-y,n}"
    msg="`echo "${2:-Select one}" | sed "s/:\s*$//"` ($opts): "
    default="`echo "$opts" | grep -oP "(?<=\[)[^/,;\|\[\]]+(?=\])"`"
    read -p "$msg" selected
    selected="${selected##* }"
    selected="${selected:-$default}"
    if ! echo "$opts" | grep -qP "(^|[/,;\|\[])$selected([/,;\|\]]|$)"; then
        >&2 echo "Invalid value '$selected', please re-input."
        select_dialog "$@"
        return
    fi
    echo "$selected"
}

# format and filter actions from user input, and expand * to all subject numbers like '1 2 3 4 5'
# code> 1: return to parent, 9: re-type in, 0: got valid actions
format_actions() {
    actions="$1"
    options="$2"
    zero_prefix="$3" # -zp, sometimes want to use "1" to install, and "01" to uninstall
    if [ -z "$actions" ]; then
        return 9
    elif echo "$actions" | grep -qP "(^|\s)0(\s|$)" && echo "$options" | grep -q "^0\."; then
        return 1
    else
        # expand the asterisk if passed in and the options available
        if echo "$actions" | grep -q "\*" && echo "$options" | grep -q "^\*\."; then
            tmp="`echo "$options" | grep -oP "^\d+" | tr "\n" " "`"
            if echo "$actions" | grep -q "0\*"; then
                tmp="`echo "$tmp" | sed -r "s/\b[1-9][0-9]*(\s|$)/0\0/g"`"
            fi
            actions="$tmp"
        fi
        acts=()
        # collect valid actions to acts
        for act in $actions; do
            # extract number from action
            num="`echo "$act" | grep -P "^([a-zA-Z0-9]+|\*)$" | sed "s/^0+//"`"
            # ltrim zero if not zero_prefix
            [ "$zero_prefix" != "-zp" ] && act="${act/#0/}"
            # must be a valid num and in options and not pushed to acts
            if [ -n "$num" -a -n "`echo "$options" | grep "^$num\."`" -a -z "`echo "${acts[@]}" | grep -P "\b$act\b"`" ]; then
                acts+=("$act")
            fi
        done
        if [ ${#acts[@]} -lt 1 ]; then
            echo "No valid actions, please re-type in."
            return 9
        fi
        echo "${acts[*]}"
    fi
}

selected_confirm() {
    actions="$1"
    options="$2"
    echo "Please confirm your selecteds:"
    for act in $actions; do
        echo "$act.`echo "$options" | grep -oP "(?<=^${act/#0/}\.).+"`"
    done
    read -p "Are you sure to continue? (y/n): " result
    test "$result" == "y"
}

# get labels by choosed actions like "1 02 3 -> docker\nmysql8.0\ngit"
acts_to_labels() {
    # acts to num branch selectors, eg. 1 02 3 -> 1|2|3
    nums="`echo "$1" | sed -r "s/(^|\s)0/\1/g" | sed -r "s/\s+/|/g"`"
    echo "$2" | grep -oP "^($nums)\..+" | sed -r "s/[^\s]+\s+(.+)/\1/g"
}

# get label branch selectors by choosed actions like "1 02 3 -> docker|mysql8\.0|git"
# $1: $acts, $2: $SUBJECT_LIST
acts_to_branch_selector() {
    readarray -t labels < <(acts_to_labels "$@")
    local IFS="|" && echo "${labels[*]}"
}

try_echo_and() {
    [ -n "$1" ] && echo "$1"
    [ -n "$2" ] && "$2"
    return 0
}

: <<EOF
Rendor the wrapped menu options.
Arg $1 format like:
    ### Please choose a job:
    "*. Do all"
    "1. Do something"
    "2. Do something2"
    "0. Return"
    ##1 Type in your choice:

Could be rendor to:
Please choose a job:
*. Do all
1. Do something
2. Do something2
0. Return
Type in your choice:

Arg $2 is the callback function name, and the remains args would be passed to the callback, allow non remain args.
The callback arg $1 is the selected numbers, the last arg is func menu_rendor's arg1, the middle args menu_rendors's callback remain args.
EOF
menu_rendor() {
    local wrapped_list="`echo "$1" | sed "s/^ *//"`"
    shift
    numbered_list="`echo "$wrapped_list" | grep -P "^([a-zA-Z0-9]+|\*)\.\s"`"
    menu_prompt="`echo "$wrapped_list" | grep -oP "(?<=^###\s).+$"`"
    prompt_line="`echo "$wrapped_list" | grep -Pm 1 "^##[:12]\s"`"
    [[ -z "$prompt_line" || "$prompt_line" == "##:"* ]] && menu_prompt_more="s (you can type in mutiple with space separator)"
    echo "${menu_prompt:-Please choose target$menu_prompt_more:}"
    echo "$numbered_list"
    menu_selected_handle "$wrapped_list" "$prompt_line" "$@"
}

menu_selected_handle() {
    local wrapped_list="$1"
    local prompt_line="$2"
    local callback="$3"
    nchars="${prompt_line:2:1}"
    [[ "$nchars" =~ ^[0-9]+$ ]] && nchars_arg="-n $nchars" || nchars_arg=""
    input_prompt="${prompt_line#* }"
    read $nchars_arg -p "${input_prompt:-Your choice:} " selected
    [[ -n "$nchars_arg" && ${#selected} -ge ${nchars} ]] && echo
    selected="`format_actions "$selected" "$wrapped_list"`"
    case "$?" in
        1) return ;;
        9) try_echo_and "$selected" && menu_selected_handle "$@" ;;
        *)
            if [ -n "$nchars_arg" ] || selected_confirm "$selected" "$wrapped_list"; then
                shift && shift && shift
                $callback "$selected" "$@" "$wrapped_list"
                echo
                menu_rendor "$wrapped_list" $callback "$@"
            else
                menu_selected_handle "$@"
            fi
        ;;
    esac
}

: <<EOF
Convert the sample data to the last part style of the doc, and then can use regular to match function to call.

Lines starting with --PART means could be the first arg as method to route to controller function.

Lines has three parts means could be the ui menu option.
Lines starting with ### means text notice would show in the ui.
Lines starting with ##[:\d] means it is an input prompt, and when the 3rd char is digit, then will auto complete input when typed chars to the limit number.
Last part in a line is the menu option description, will auto prepend an increment menu number if not start with "[a-zA-Z0-9*]. ", or else will be as a custom number.

    ### Please choose ajob
    --client-install              client_install
    --server-install              server_install              "Install the server"
    do_all                        "*. Do all"
    return                        "0. Return"
    ##1 Type in your choice

### Please choose ajob
--client-install | client_install
--server-install | server_install
1. Install the server | server_install
*. Do all | do_all
0. Return | return
##1 Type in your choice
EOF
menu_options_format() {
    num=0
    options=()
    while read line <&3; do
        readarray -t parts < <(xargs -n1 <<< "$line")
        if [[ "${parts[0]}" = "##"* ]]; then
            description=""
            options+=("`echo "$line" | sed -r "s/^\s+//"`")
        elif [[ "${parts[0]}" = --* ]]; then
            command="${parts[1]}"
            description="${parts[2]}"
            options+=("${parts[0]} | $command")
        else
            command=${parts[0]}
            description="${parts[1]}"
        fi
        if echo "$description" | grep -qP "^([a-zA-Z0-9]+|\*)\.\s"; then
            options+=("$description | $command")
        elif [ -n "$description" ]; then
            let num++
            options+=("$num. $description | $command")
        fi
    done 3<<< "$1"
    for item in "${options[@]}"; do echo "$item"; done
}

: <<EOF
Route by $2 method arg via menu option rules, otherwise, show menu ui if no $2 passed or not matched a command via $2.
$1 is the option rules, refer to the 'menu_options_format' doc for the format.
The args after $2 will be append to the route command call.
EOF
menu_route_or_rendor() {
    local formatted="`menu_options_format "$1"`"
    method="$2"
    [ -n "$method" ] && command="`echo "$formatted" | grep -vP "^(([a-zA-Z0-9]+|\*)\.|##[#:12])\s" | grep -oP "(?<=^$method\s\|\s).+"`" || command=""
    if [ -z "$command" ]; then
        local menu_config="`echo "$formatted" | grep -P "^((\w+|\*)\.|##.)\s" | sed -r "s/^(([a-zA-Z0-9]+|\*)\.\s[^|]+)\s+\|.+$/\1/"`"
        menu_rendor "$menu_config" menu_handle_selected "$formatted"
        return
    fi
    shift; shift
    $command "$@"
}

menu_handle_selected() {
    command="`echo "$2" | grep -P "^$1\.\s" | grep -oP "(?<=\|\s)[^|]+$"`"
    readarray -t commands < <(echo "$command" | xargs -n1)
    "${commands[@]}"
}

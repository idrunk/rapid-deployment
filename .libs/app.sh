#!/bin/bash

source "`dirname "$0"`/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"

# Change the env's mod time as the condition to judge the subject's env is need a confirm dialog
touch -m "$LIB_DIR/.env"

edit_env() {
    confirm_envs "$LIB_DIR/.env" INSTL_ROOT/ BASE_PORT BASE_DOMAIN CLIENT_NAME
    build_instl_subj_envs
}

build_subject_list() {
    [ -z "$SUBJECT_LIST" ] && SUBJECT_LIST="`find "$APP_ROOT" -name *"-install.sh" | grep -noP "[^/]+/[^/]+$" | sed -re "s|^([^/]+)/(\w+).+$|\1(\2)|" -re "s|\(pkg\)$||" -e "s/:/. /"`"
}

install_route() {
    build_subject_list
    echo
    read -d "" -r menu_options <<EOF
        ### Please choose targets to ${1/#--/} (you can type in mutiple with space separator):
        *. Choose all
        $SUBJECT_LIST
        0. Return to the upper directory
EOF
    menu_rendor "$menu_options" handle_install_route "$1"
}

handle_install_route() {
    actions="$1"
    method="$2"
    wrapped_list="$3"
    labels="`acts_to_labels "$actions" "$wrapped_list"`"
    pkg_branch_selector="`echo "$labels" | grep -P '(?<!\(docker\))$' | paste -sd "|" -`"
    docker_branch_selector="`echo "$labels" | grep -oP '.+(?=\(docker\)$)' | paste -sd "|" -`"
    if [ "$method" == "--install" ]; then
        find "$COMMON_DIR" -exec bash -c 'sp="{}"; tp="${sp/#$APP_ROOT/$INSTL_ROOT}"; [ -d "$sp" ] && mkdir -p "$tp" || /bin/cp -frv "$sp" "$tp"' \;
        call_install_script "$method" "$pkg_branch_selector"
    fi
    if [ -n "$docker_branch_selector" ]; then
        [ "$method" == "--install" ] && "$INSTL_COMMON_DIR/docker-util.sh" -cn
        call_install_script "$method" "$docker_branch_selector" docker
    fi
    # uninstall should be the reverse order
    [ "$method" != "--install" ] && call_install_script "$method" "$pkg_branch_selector"
}

call_install_script() {
    method="$1"
    branch_selector="$2"
    scripts="$(find "$APP_ROOT" -regextype egrep -regex ".+/($branch_selector)/${3:-pkg}-install.sh$")"
    local IFS=$'\n'
    [ "$method" == "--install" ] && for file in `echo "$scripts"`; do
        "$file" --init-env
    done
    [ -n "$3" ] && mark="($3)" || mark=""
    for file in `echo "$scripts"`; do
        subj_name="`echo "$file" | grep -oP "[^/]+(?=/[^/]+$)"`$mark"
        echo $'\n'"Begin $subj_name $method"
        "$file" "$method"
        echo "Finished $subj_name $method"
    done
}

uninstall_clear_all() {
    echo
    ! confirm_dialog "[y]/n" "Warnning !!! You will uninstall and remove all data under '$INSTL_ROOT', and it will not be recoverable, really want to continue?" && return
    ! confirm_dialog "confirm/n" "Last chance, type in 'confirm' to continue to clear, or 'n' to cancel" && return
    build_subject_list
    acts="`format_actions "*" "*. All\n$SUBJECT_LIST"`"
    handle_install_route "$acts" --uninstall "$SUBJECT_LIST"
    handle_install_route "$acts" --clear-data "$SUBJECT_LIST"
    "$INSTL_COMMON_DIR/docker-util.sh" -rn
    echo "Clear completed."
}

subject_tools() {
    echo
    read -d "" -r menu_options <<EOF
        ### Select one subject tool you want run:
        s. System init package box
        `find "$APP_ROOT" -maxdepth 2 -mindepth 2 -name tool.sh | grep -noP "[^/]+(?=/tool.sh$)" | sed -r "s/(^[0-9]+):/\1. /"`
        0. Return the parent menu
        ##1 Your select:
EOF
    menu_rendor "$menu_options" run_sys_tool
}

run_sys_tool() {
    echo
    case "$1" in
        "s") "$SYSTEM_DIR/tool.sh" --sysinit-package-box ;;
        *) "$APP_ROOT/`echo "$2" | grep -oP "(?<=$1\.\s).+$"`/tool.sh" ;;
    esac
}

menu_route_or_rendor "`cat <<EOF
    ### Please choose one job:
    edit_env                            "e. Edit env [INSTL_ROOT=$INSTL_ROOT; BASE_PORT=$BASE_PORT]"
    'install_route --install'           'Install'
    'install_route --uninstall'         'Uninstall'
    'install_route --clear-data'        'Clear data'
    'install_route --rmi'               'Clear image'
    uninstall_clear_all                 'Uninstall and clear all'
    subject_tools                       'Subject tools'
    exit                                '0. Quit'
    ##1 Your choice:
EOF
`"
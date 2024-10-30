#!/bin/bash

source "`dirname "$0"`/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"

# Change the env's mod time as the condition to judge the subject's env is need a confirm dialog
touch -m "$LIB_DIR/.env"

pack_route() {
    operation="$1"
    if [ "${operation:---tar}" == "--tar" ]; then
        read -p "Please type in the target dir to save package: " target_dir
        target_dir="`realpath "$target_dir"`"
        if [ ! -d "$target_dir" ]; then
            pack_route "$operation"
            return 0
        fi
        if [ "$target_dir" == "`dirname "$APP_ROOT"`" ]; then
            echo "Target dir cannot be '$target_dir'."
            pack_route "$operation"
            return 0
        fi
        echo "Target directory is '$target_dir'"
    fi
    echo
    read -d "" -r menu_options <<EOF
        ### Please choose targets to `echo "${operation:-pack}" | sed s/-//g` (you can type in mutiple with this space separator):
        *. Choose all
        `find "$APP_ROOT" -name "pack.sh" | grep -noP "[^/]+(?=/pack.sh)" | sed "s/:/. /"`
        0. Return to the upper directory
EOF
    menu_rendor "$menu_options" pack_route_handle "$operation" "$target_dir"
}

pack_route_handle() {
    actions="$1"
    operation="$2"
    target_dir="$3"
    wrapped_list="$4"
    [ "${operation:---tar}" == "--tar" ] && do_pack_installers_to "$operation" "$wrapped_list" "$actions" "$target_dir" || do_prepare_installers "$operation" "$wrapped_list" "$actions"
    return
}

do_pack_installers_to() {
    operation="$1" # --tar
    wrapped_list="$2"
    actions="$3"
    pack_dir="$4/$app_name"
    app_name="`basename "$APP_ROOT"`"
    mkdir -p "$pack_dir/.libs/"{.images,.packages}
    /bin/cp -rfv "$APP_ROOT/"{common,adm,app} "$pack_dir/"
    find "$LIB_DIR" -mindepth 1 -maxdepth 1 -regextype egrep ! -regex ".+/\.(env|images|packages)" -exec /bin/cp -rfv "{}" "$pack_dir/.libs/" \;
    find "$APP_ROOT" -regextype egrep -regex ".+/(`acts_to_branch_selector "$actions" "$wrapped_list"`)/pack.sh" | while read file; do
        "$file" --pack-to "$pack_dir"
    done
    if [ "$operation" == "--tar" ]; then
        tar -cvf "$pack_dir.tar" -C"$4" "$app_name"
        echo "Package was prepared on '$pack_dir.tar'"
    else
        echo "Package was prepared on '$pack_dir'"
    fi
}

do_prepare_installers() {
    operation="$1" # --download, --remove
    wrapped_list="$2"
    actions="$3"
    find "$APP_ROOT" -regextype egrep -regex ".+/(`acts_to_branch_selector "$actions" "$wrapped_list"`)/pack.sh" | while read file; do
        "$file" "$operation"
    done
}

data_management() {
    echo
    menu_route_or_rendor "`cat <<EOF
        ### Please choose one job:
        "'$LIB_DIR/log.sh' --rotate"    'Log rotate'
        "'$LIB_DIR/log.sh' --gzip"      'Gzip rotated logs'
        clear_env_files                 'Clear env data'
        return                          '0. Return the upper directory'
        ##1 Your choice:
EOF
`"
}

clear_env_files() {
    ! confirm_dialog "[y]/n" "Sure want to clear?" && return
    find "$APP_ROOT" -name .env | while read file; do
        rm -rfv "$file"
    done
    echo "Clear completed."
}

menu_route_or_rendor "`cat <<EOF
    ### Please choose one job:
    'pack_route --download'                         'Prepare the installation source'
    'pack_route --remove'                           'Remove the installation source'
    'pack_route'                                    'Pack installers to'
    'pack_route --tar'                              'Pack installers package to'
    'data_management'                               'Data management'
    "try_echo_and ' ' '$ADMIN_DIR/admin.sh'"        'Share the rapid deployment tool'
    exit                                            '0. Quit'
    ##1 Your choice:
EOF
`"
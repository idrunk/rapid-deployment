#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"
source "$SUBJ_DIR/lib.sh"

sysinit_package_box() {
    read -d "" -r wrapped_list <<EOF
        ### Please choose targets to install (or prefix with '0' to remove) (you can type in mutiple with space separator):
        *. Choose all
        `pkg_list_of_os | grep -noP "^\S+" | sed -e "s/\r//" -e "s/:/. /"`
        0. Return to the parent menu
EOF
    menu_rendor "$wrapped_list" installer_handle
}

installer_handle() {
    acts_install=()
    acts_remove=()
    for act in $1; do
        [ "${act::1}" == "0" ] && acts_remove+=($act) || acts_install+=($act)
    done
    if [[ ${#acts_install[*]} > 0 ]]; then
        readarray -t labels < <(acts_to_labels "${acts_install[*]}" "$2")
        pkgm_install "${labels[@]}"
    fi
    if [[ ${#acts_remove[*]} > 0 ]]; then
        mapfile -t labels <<< "`acts_to_labels "${acts_remove[*]}" "$2"`"
        pkgm_uninstall "${labels[@]}"
        systemctl daemon-reload
    fi
}

init() {
    set_hostname
    confirm_dialog "[y]/n" "Set timezone to 'Shanghai'?" && set_tz_shanghai
    confirm_dialog "[y]/n" "Set source mirror?" && set_source_mirror
    confirm_dialog "[y]/n" "Disable selinux?" && disable_selinux
    confirm_dialog "[y]/n" "Disable swap?" && disable_swap
    confirm_dialog "[y]/n" "Enable cgroupv2?" && enable_cgroup2
    confirm_dialog "[y]/n" "Set sshd config?" && set_sshd_config
    confirm_dialog "y/[n]" "Enable cockpit?" && enable_cockpit
    confirm_dialog "y/[n]" "Reboot to take effect?" && reboot
}

create_sys_users() {
    while read -r line <&3; do
        # declare -a arr="($line)" # this can also do parse quoted arg, but not for unquoted arg with special char like ';'
        readarray -t arr < <(xargs -n1 <<< "$line")
        create_sys_user "${arr[@]}"
    done 3< <(cat "$INSTL_SYSTEM_DIR/sys-user.list" | grep -v "^\s*$")
}

menu_route_or_rendor '
    --sysinit-package-box       sysinit_package_box
    --init                      init                    "r. Run the init process"
    --set-hostname              set_hostname            "Set hostname"
    --set-tz-shanghai           set_tz_shanghai         "Set tz shanghai"
    --set-dns                   set_dns                 "Set DNS"
    --set-source-mirror         set_source_mirror       "Set source mirror"
    --disable-selinux           disable_selinux         "Disable selinux"
    --disable-swap              disable_swap            "Disable swap"
    --enable-cgroup2            enable_cgroup2          "Enable cgroup2"
    --enable-cockpit            enable_cockpit          "Enable cockpit"
    --remove-cockpit            remove_cockpit          "Remove cockpit"
    --set-sshd-config           set_sshd_config         "Set sshd config"
    --create-sys-user           create_sys_user
    --delete-sys-user           delete_sys_user
    --create-sys-user-list      create_sys_users        "Create sys users"
                                return                  "0. Return to parent menu"
    ##2 Your choice:
' "$@"
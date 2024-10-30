#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$SYSTEM_DIR/lib.sh"

daemon_name="smb`os_like | grep -q debian && echo d`"

init_smb() {
    user_list_password_completion "$SUBJ_DIR/smb-user.list" && rewrite_to "$INSTL_SUBJ_DIR/smb-user.list" "$SUBJ_DIR/smb-user.list"
    init_smb_config && \
    init_smb_groups && \
    init_smb_users
}

init_smb_config() {
    net conf showshare users > /dev/null && return
    # Comment out the [homes] part
    sed -e 's/^\s*\[homes\]/#\0/' -re '/^#\s*\[homes\]/,/^\s*[;#]?\s*\[/ {/^\s*[;#]?\s*\[\w+/b; s/^[^;#]/#\0/ }' -i /etc/samba/smb.conf
    # inclusion of net registry
    ! grep -qP "^\s*include\s*=\s*registry\s*$" /etc/samba/smb.conf && sed -i "/\[global\]/a include = registry" /etc/samba/smb.conf
    systemctl restart $daemon_name
    mkdir -p "$SHARE_USER_ROOT"
    net conf addshare "users" "$SHARE_USER_ROOT" writeable=y
}

init_smb_groups() {
    while read line <&3; do
        readarray -t arr < <(xargs -n1 <<< "$line")
        net conf addshare "${arr[0]}" "${SHARE_ROOT}/${arr[0]}" writeable=y
        group_dir_set_acl "${arr[@]}"
    done 3< <(cat "$INSTL_SUBJ_DIR/smb-group.list" | grep -v "^\s*$")
}

group_dir_set_acl() {
    dir="$SHARE_ROOT/$1"
    groups=(`echo "$2" | xargs -d ";"`)
    mkdir -p "$dir"
    chmod 0770 "$dir"
    for acl in "${groups[@]}"; do
        arr=(`echo "$acl" | xargs -d ":"`)
        group="${arr[0]}"
        permissions="${arr[1]}"
        groupadd -f "$group"
        # set permissions if defined, or remove them of the group
        if [ -n "$permissions" ]; then
            setfacl -m g:$group:$permissions "$dir"
        else
            setfacl -x g:$group "$dir"
        fi
    done
}

init_smb_users() {
    while read line <&3; do
        readarray -t arr < <(xargs -n1 <<< "$line")
        create_smb_user "${arr[@]}"
    done 3< <(cat "$INSTL_SUBJ_DIR/smb-user.list" | grep -v "^\s*$")
    systemctl restart $daemon_name
}

create_smb_user() {
    declare -a uinfo="(`create_sys_user "$@"`)"
    user="${uinfo[0]}"
    password="${uinfo[1]:-`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`}"
    pdbedit -a "$user" -t <<< "$password"$'\n'"$password"
    mkdir -p "$SHARE_USER_ROOT/$user"
    chmod 0750 "$SHARE_USER_ROOT/$user"
    chown "$user":"$user" "$SHARE_USER_ROOT/$user"
}

delete_smb_user() {
    pdbedit -x "$1"
    # delete_sys_user "$1"
}

init_env() {
    # ND means non-default
    check_confirm_envs "$SUBJ_ENV" \
        "SHARE_ROOT/=${SHARE_ROOT:-$INSTL_SUBJ_DIR/samba/data}" \
        "SHARE_USER_ROOT/=${SHARE_USER_ROOT:-$INSTL_SUBJ_DIR/samba/data/users}" \
        SMB_ND_NETBIOS_PORT=`assemble_port $SMB_ND_NETBIOS_TOP_PORT` \
        SMB_ND_TCP_PORT=`assemble_port $SMB_ND_TCP_TOP_PORT`
    # confirm_env "$SUBJ_ENV" SHARE_ROOT/
    # if [ -z "$SHARE_USER_ROOT" ]; then
    #     persistence_env "$SUBJ_ENV" "SHARE_USER_ROOT=$SHARE_ROOT/users"
    #     mkdir -p "$SHARE_USER_ROOT"
    # fi
    # confirm_env "$SUBJ_ENV" SHARE_USER_ROOT/
}

menu_route_or_rendor '
    --init-smb              init_smb                "Initialize samba config and create group and user and bind folders with list file"
    --init-smb-groups       init_smb_groups         "Create group bind folders with list file"
    --init-smb-users        init_smb_users          "Create user and bind folders with list file"
    --group-dir-set-acl     group_dir_set_acl
    --create-smb-user       create_smb_user
    --delete-smb-user       delete_smb_user
    --init-env              init_env
                            return                  "0. Return to parent menu"
    ##1 Your choice:
' "$@"

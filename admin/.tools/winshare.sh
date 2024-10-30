#!/bin/bash

source "`dirname "$0"`/../../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$SYSTEM_DIR/lib.sh"

init_env() {
    "$SUBJ_DIR/.tools/samba.sh" --init-env
}

smb_portproxy() {
    init_env
    portproxy $SMB_ND_TCP_PORT "*" 445 "127.0.0.1"
    portproxy $SMB_ND_NETBIOS_PORT "*" 139 "127.0.0.1"
    portproxy_showall
}

smb_portproxy_del() {
    init_env
    portproxy_del $SMB_ND_TCP_PORT "*"
    portproxy_del $SMB_ND_NETBIOS_PORT "*"
    portproxy_showall
    echo "Deleted."
}

share() {
    init_env
    w_app_root="`echo "${SHARE_ROOT////\\\\}" | sed -r 's|^\\\\([a-z])\\\\|\1:\\\\|g'`"
    net share $SHARE_NAME="$w_app_root" //grant:$SMB_USER,FULL //UNLIMITED
    showmount
}

unshare() {
    init_env
    net share $SHARE_NAME //delete
    net share
    echo "Deleted."
}

showmount() {
    "$SUBJ_DIR/.tools/samba.sh" --showmount
}

menu_route_or_rendor '
    ### Choose an action (Need to run in administrator(sudo) mode):
    share                   "Share"
    unshare                 "Unshare"
    showmount               "Show the mount conmand"
    smb_portproxy           "Smb portproxy"
    smb_portproxy_del       "Smb portproxy del"
    return                  "0. Return to the parent menu"
    ##1 Your choice:
' "$@"
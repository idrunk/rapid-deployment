#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"

__init_env() {
    "$SUBJ_DIR/tool.sh" --init-env
}

__install() {
    pkgm_install samba
    [ "`os_like`" == "rhel" ] && systemctl enable smb --now
}

__uninstall() {
    pkgm_uninstall samba
}

pkg_handle "$@"
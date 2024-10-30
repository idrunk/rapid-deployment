#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"

__init_env() {
    "$SUBJ_DIR/tool.sh" --confirm-subj-env
}

__install() {
    "$SUBJ_DIR/tool.sh" --edge-install
}

__uninstall() {
    "$SUBJ_DIR/tool.sh" --edge-uninstall
}

pkg_handle "$@"
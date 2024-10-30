#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"

__init_env() {
    "$SUBJ_DIR/tool.sh" --init-env
}

__install() {
    "$SUBJ_DIR/tool.sh" --install
}

__after_install() {
    : # just to suppress the env display
}

__uninstall() {
    "$SUBJ_DIR/tool.sh" --uninstall
}

pkg_handle "$@"

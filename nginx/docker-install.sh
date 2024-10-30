#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    rewrite_to "$INSTL_SUBJ_DIR/nginx/nginx.conf" "$SUBJ_RES_DIR/nginx.conf"
}

__before_uninstall() {
    [ "0" == "`ls -1 "$INSTL_SUBJ_DIR/nginx/conf.d" | wc -l`" ] && return
    echo "Unable to uninstall, there are related dependent conf in 'conf.d'." >&2
    exit 1
}

docker_handle "$@"
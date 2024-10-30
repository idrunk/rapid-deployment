#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    check_confirm_envs "$SUBJ_ENV" \
        "POSTGRES_PASSWORD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`" \
        "POSTGRES_PORT=`assemble_port $POSTGRES_TOP_PORT`" \
        "PGWEB_PORT=`assemble_port $PGWEB_TOP_PORT`"
}

__before_uninstall() {
    [ "0" == "`ls -1 "$INSTL_SUBJ_DIR/postgres/initdb.d" | wc -l`" ] && return
    echo "Unable to uninstall, there are related dependent script in 'initdb.d'." >&2
    exit 1
}

docker_handle "$@"
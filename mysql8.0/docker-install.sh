#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    rewrite_to "$INSTL_SUBJ_DIR/mysql/conf.d/mysql.cnf" "$SUBJ_RES_DIR/mysql.cnf"
    check_confirm_envs "$SUBJ_ENV" \
        "MYSQL_ROOT_PASS=`cat /dev/urandom | tr -dc 'A-Za-z0-9_' | head -c 64`" \
        "MYSQL_PORT=`assemble_port $MYSQL_TOP_PORT`" \
        "ADMINER_PORT=`assemble_port $ADNINER_TOP_PORT`"
}

__before_uninstall() {
    [ "0" == "`ls -1 "$INSTL_SUBJ_DIR/mysql/initdb.d" | wc -l`" ] && return
    echo "Unable to uninstall, there are related dependent script in 'initdb.d'." >&2
    exit 1
}

docker_handle "$@"
#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"
source "$SYSTEM_DIR/lib.sh"
source "$MYSQL80_DIR/lib.sh"

__init_env() {
    rewrite_to "$INSTL_SUBJ_DIR/nginx/nginx.conf" "$SUBJ_RES_DIR/nginx.conf"
    "$MYSQL80_DIR/docker-install.sh" --init-env
    try_load_env "$INSTL_MYSQL80_DIR/.env"
    rewrite_to "$SUBJ_ENV" <<EOF
MYSQL_HOST=mysql80
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS}
LOCAL_HOST_IP4=`get_ip4_local`
SF_PORT=`assemble_port $SF_TOP_PORT`
SF_ADMIN_EMAIL=seafile@syy.pub
SF_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
SF_DB_USER=seafile
EOF
}

__before_install() {
    "$MYSQL80_DIR/docker-install.sh" --install
}

__after_install() {
    [ -n "$SF_DB_PASS" ] && return
    # change the seafile mysql user to 'mysql_native_password' type authentication plugin, otherwise the program cannot run properly
    while ! docker logs seafile -n 100 2> /dev/null | grep -q "Seahub is started"; do
        echo "Waiting for seafile db data init..."
        sleep 5
    done
    SF_DB_PASS="`grep -FA 10 "[database]" "$INSTL_SEAFILE_DIR"/seafile/seafile/conf/seafile.conf | grep -oP "(?<=password\s=\s)\S+"`"
    docker_mysql_query "ALTER USER '$SF_DB_USER'@'%.%.%.%' IDENTIFIED WITH mysql_native_password BY '$SF_DB_PASS'"
    persistence_env "$SUBJ_ENV" "SF_DB_PASS=$SF_DB_PASS"
    docker restart seafile > /dev/null
}

docker_handle "$@"
#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"
source "$MYSQL80_DIR/lib.sh"

__init_env() {
    "$MYSQL80_DIR/docker-install.sh" --init-env
    try_load_env "$INSTL_MYSQL80_DIR/.env"
    rewrite_to "$SUBJ_ENV" <<EOF
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS}
OO_DB_USER=onlyoffice
OO_DB_PASS=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
JWT_SECRET=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 40)
OO_ADMIN_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
OO_PORT=`assemble_port $OO_TOP_PORT`
EOF
}

__before_install() {
    mysql_initdb_mod onlyoffice.sql.txt < <(envsubst < "$SUBJ_RES_DIR/onlyoffice.sql.txt.tpl")
    "$MYSQL80_DIR/docker-install.sh" --install
    docker_mysql_exec onlyoffice.sql.txt
}

__after_install() {
    echo "The 'OO_ADMIN_PASSWD' you need to copy it and paste to the init page to finish the register."
}

__clear_data() {
    mysql_initdb_mod onlyoffice.sql.txt
    subj_clear
}

docker_handle "$@"
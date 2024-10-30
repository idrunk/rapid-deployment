#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"
source "$SYSTEM_DIR/lib.sh"
source "$NGINX_DIR/lib.sh"
source "$MYSQL80_DIR/lib.sh"

__init_env() {
    "$MYSQL80_DIR/docker-install.sh" --init-env
    "$NGINX_DIR/docker-install.sh" --init-env

    rewrite_to "$SUBJ_ENV" <<EOF
MYSQL_HOST=mysql80
NC_DB_NAME=nextcloud
NC_DB_USER=nextcloud
NC_DB_PASS=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
NC_ADMIN_USER=ncadmin
NC_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
NC_TRUSTED_DOMAINS=`get_ip4_local`
NC_PORT=`assemble_port $NC_TOP_PORT`
EOF
}

__before_install() {
    nginx_conf_mod nextcloud.conf < <(sed "s/\$NC_PORT\b/$NC_PORT/" "$SUBJ_DIR/.res/nginx.conf")
    nginx_docker_mapping_mod ports "'$NC_PORT:$NC_PORT'"
    nginx_docker_mapping_mod volumes "../nextcloud/nextcloud/:/var/www/html:ro"
    "$MYSQL80_DIR/docker-install.sh" --install
    mysql_initdb_mod nextcloud.sql.txt < <(envsubst < "$SUBJ_RES_DIR/nextcloud.sql.tpl")
    docker_mysql_exec nextcloud.sql.txt
}

__after_install() {
    "$NGINX_DIR/docker-install.sh" --install
}

__clear_data() {
    mysql_initdb_mod nextcloud.sql.txt
    nginx_conf_mod nextcloud.conf
    nginx_docker_mapping_mod ports -rm "'$NC_PORT:$NC_PORT'"
    nginx_docker_mapping_mod volumes -rm "../nextcloud/nextcloud/:/var/www/html:ro"
    "$NGINX_DIR/docker-install.sh" --install
    subj_clear
}

docker_handle "$@"
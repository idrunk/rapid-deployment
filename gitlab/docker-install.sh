#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"
source "$SYSTEM_DIR/lib.sh"
source "$NGINX_DIR/lib.sh"
source "$POSTGRES_DIR/lib.sh"

__init_env() {
    "$POSTGRES_DIR/docker-install.sh" --init-env
    "$NGINX_DIR/docker-install.sh" --init-env

    rewrite_to_try_load_env "$SUBJ_ENV" <<EOF
GL_WEB_PORT=`assemble_port $GL_WEB_TOP_PORT`
GL_SSH_PORT=`assemble_port $GL_SSH_TOP_PORT`
GL_DB_HOST=postgres
GL_DB_USER=gitlab
GL_DB_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
GL_ROOT_USER=root
GL_ROOT_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
EOF

    postgres_initdb_mod gitlab.sql.txt <<< "CREATE ROLE $GL_DB_USER WITH LOGIN PASSWORD '$GL_DB_PASSWD';
CREATE DATABASE gitlabhq_production WITH OWNER = $GL_DB_USER ENCODING = 'UTF8';"
}

__before_install() {
    rewrite_to "$INSTL_SUBJ_DIR/gitlab/config/gitlab.rb" < <(envsubst < "$SUBJ_DIR/.res/gitlab.rb")
    nginx_docker_mapping_mod ports $GL_WEB_PORT:$GL_WEB_PORT
    nginx_conf_mod gitlab.conf < <(sed "s/\$GL_WEB_PORT\b/$GL_WEB_PORT/" "$SUBJ_RES_DIR/nginx.conf")
    "$POSTGRES_DIR/docker-install.sh" --install
    "$NGINX_DIR/docker-install.sh" --install
    docker_postgres_exec gitlab.sql.txt
}

__clear_data() {
    postgres_initdb_mod gitlab.sql.txt
    nginx_conf_mod gitlab.conf
    nginx_docker_mapping_mod ports -rm $GL_WEB_PORT:$GL_WEB_PORT
    "$NGINX_DIR/docker-install.sh" --install
    subj_clear
}

docker_handle "$@"
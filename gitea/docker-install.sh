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

    rewrite_to_try_load_env "$SUBJ_ENV" <<EOF
GT_WEB_HOST=`get_ip4_local`
GT_WEB_PORT=`assemble_port $GT_WEB_TOP_PORT`
GT_SSH_PORT=`assemble_port $GT_SSH_TOP_PORT`
GT_DB_HOST=mysql80
GT_DB_NAME=gitea
GT_DB_USER=gitea
GT_DB_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
GT_ADMIN_USER=gitea
GT_ADMIN_EMAIL=gitea@syy.pub
GT_ADMIN_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
EOF
}

__before_install() {
    nginx_docker_mapping_mod ports "'$GT_WEB_PORT:$GT_WEB_PORT'"
    nginx_conf_mod gitea.conf < <(envsubst < "$SUBJ_RES_DIR/nginx.conf")
    mysql_initdb_mod gitea.sql.txt < <(envsubst < "$SUBJ_RES_DIR/mysql.sql.tpl")

    "$NGINX_DIR/docker-install.sh" --install
    "$MYSQL80_DIR/docker-install.sh" --install
    docker_mysql_exec gitea.sql.txt
}

__after_install() {
    while ! docker logs gitea -n 20 | grep -Fq "[I] Listen: http"; do
        echo "Waiting for gitea ready."
        sleep 2
    done
    curl -H "Content-type: application/x-www-form-urlencoded" -d "db_type=mysql" -d "db_host=$GT_DB_HOST:3306" -d "db_user=$GT_DB_USER" -d "db_passwd=$GT_DB_PASSWD" \
        -d "db_name=$GT_DB_NAME" -d "ssl_mode=disable" -d "db_schema=" -d "db_path=%2Fdata%2Fgitea%2Fgitea.db" -d "app_name=Gitea%3A+Git+with+a+cup+of+tea" \
        -d "repo_root_path=%2Fdata%2Fgit%2Frepositories" -d "lfs_root_path=%2Fdata%2Fgit%2Flfs" -d "run_user=git" -d "domain=$GT_WEB_HOST" -d "ssh_port=$GT_SSH_PORT" \
        -d "http_port=$GT_WEB_PORT" -d "app_url=http%3A%2F%2F${GT_WEB_HOST}%3A9960%2F" -d "log_root_path=%2Fdata%2Fgitea%2Flog" -d "smtp_addr=" -d "smtp_port=" \
        -d "smtp_from=" -d "smtp_user=" -d "smtp_passwd=" -d "offline_mode=on" -d "disable_gravatar=on" -d "enable_open_id_sign_in=on" -d "enable_open_id_sign_up=on" \
        -d "default_allow_create_organization=on" -d "default_enable_timetracking=on" -d "no_reply_address=noreply.$GT_WEB_HOST" -d "password_algorithm=pbkdf2" \
        -d "admin_name=$GT_ADMIN_USER" -d "admin_email=$GT_ADMIN_EMAIL" -d "admin_passwd=$GT_ADMIN_PASSWD" -d "admin_confirm_passwd=$GT_ADMIN_PASSWD" \
        -X POST http://$GT_WEB_HOST:$GT_WEB_PORT/ -so /dev/null
}

__clear_data() {
    mysql_initdb_mod gitea.sql.txt
    nginx_conf_mod gitea.conf
    nginx_docker_mapping_mod ports -rm "'$GT_WEB_PORT:$GT_WEB_PORT'"
    "$NGINX_DIR/docker-install.sh" --install
    subj_clear
}

docker_handle "$@"
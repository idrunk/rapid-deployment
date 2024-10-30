#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    [ -d "$INSTL_SUBJ_DIR/cloudreve/conf.ini" ] && rm -rf "$INSTL_SUBJ_DIR/cloudreve/conf.ini"
    [ -d "$INSTL_SUBJ_DIR/cloudreve/cloudreve.db" ] && rm -rf "$INSTL_SUBJ_DIR/cloudreve/cloudreve.db"
    [ ! -f "$INSTL_SUBJ_DIR/cloudreve/conf.ini" ] && rewrite_to "$INSTL_SUBJ_DIR/cloudreve/conf.ini" <<< ""
    [ ! -f "$INSTL_SUBJ_DIR/cloudreve/cloudreve.db" ] && rewrite_to "$INSTL_SUBJ_DIR/cloudreve/cloudreve.db" <<< ""
    rewrite_to "$SUBJ_ENV" <<< "CLOUDREVE_PORT=`assemble_port $CLOUDREVE_TOP_PORT`"
}

__after_install() {
    if os_like | grep -q rhel; then
        firewall-cmd --add-port 9982/tcp --permanent --zone=public
        firewall-cmd --reload
    fi
    sleep 3
    if docker logs cloudreve | grep -qoP "Admin\s+(user\s+name|password):\s*.+"; then
        readarray -t account < <(docker logs cloudreve | grep -oP "Admin\s+(user\s+name|password):\s*.+" | sed -r "s/^[^:]+:\s*//")
        persistence_env "$SUBJ_ENV" "CLOUDREVE_ADMIN_USERNAME=${account[0]}" "CLOUDREVE_ADMIN_PASSWORD=${account[1]}"
        rewrite_to "$INSTL_SUBJ_DIR/.env" "$SUBJ_ENV"
    fi
}

docker_handle "$@"
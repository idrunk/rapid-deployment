#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"
source "$SYSTEM_DIR/lib.sh"

confirm_subj_env() {
    check_confirm_envs "$SUBJ_ENV" \
        BASE_PORT=$BASE_PORT \
        FRP_TOKEN="${FRP_TOKEN:-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 32`}" \
        FRP_SERVER_HOST=${FRP_SERVER_HOST:-$BASE_DOMAIN} \
        FRP_SERVER_PORT=${FRP_SERVER_PORT:-`assemble_port $FRP_SERVER_TOP_PORT`} \
        FRP_USER=${FRP_USER:-frp_$CLIENT_NAME} \
        FRP_USER_PASS="${FRP_USER_PASS:-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 8`}" \
        LOCAL_IP4="`get_ip4_local`" \
        LOCAL_SSH_NAME=${LOCAL_SSH_NAME:-ssh-`hostname`} \
        LOCAL_SSH_REMOTE_PORT=${LOCAL_SSH_REMOTE_PORT:-`assemble_port $LOCAL_SSH_REMOTE_TOP_PORT`} \
        FRP_SERVER_WEB_PORT=${FRP_SERVER_WEB_PORT:-`assemble_port $FRP_SERVER_WEB_TOP_PORT`} \
        FRP_SERVER_WEB_USER=${FRP_SERVER_WEB_USER:-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 8`} \
        FRP_SERVER_WEB_PASSWORD=${FRP_SERVER_WEB_PASSWORD:-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 32`}
    export SERVER_INSTL_DIR="$INSTL_SUBJ_DIR.server-$FRP_SERVER_PORT"
}

export SERVER_INSTL_DIR="$INSTL_SUBJ_DIR.server-$FRP_SERVER_PORT"

server_install() {
    confirm_subj_env
    rewrite_to "$SERVER_INSTL_DIR/.env" "$SUBJ_ENV"
    rewrite_to "$SERVER_INSTL_DIR/frps.toml" "$SUBJ_RES_DIR/frps.toml"
    rewrite_to "$SERVER_INSTL_DIR/docker-compose.yml" "$SUBJ_RES_DIR/docker-compose.server.yml"
    server_add_user "$FRP_USER" "$FRP_USER_PASS"
    docker compose -f "$SERVER_INSTL_DIR/docker-compose.yml" up -d
}

server_uninstall() {
    docker compose -f "$SERVER_INSTL_DIR/docker-compose.yml" down
    echo "Server uninstalled."
}

server_add_user() {
    kv="$1=${2:-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 8`}"
    match_replace_or_append "$SERVER_INSTL_DIR/tokens" "^$1=" "$kv"
    [ -z "$2" ] && echo $kv
}

menu_route_or_rendor '
    ### The frp management tool:
    --confirm-subj-env              confirm_subj_env
    --server-install                server_install              "Install frp server(docker)"
    --server-uninstall              server_uninstall            "Uninstall frp server(docker)"
    --server-add-user               server_add_user
    return "0. Return"
    ##1 choose a job:
' "$@"
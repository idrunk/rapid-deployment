#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"

confirm_subj_env() {
    check_confirm_envs "$SUBJ_DIR/.env" \
        N2N_COMMUNITY="${N2N_COMMUNITY:-$CLIENT_NAME-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 16`}" \
        N2N_KEY="${N2N_KEY:-`cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c 64`}" \
        N2N_ADDRESS \
        N2N_SUPERNODE_HOST=${N2N_SUPERNODE_HOST:-$BASE_DOMAIN} \
        N2N_SUPERNODE_PORT=${N2N_SUPERNODE_PORT:-`assemble_port 22`}
    export INSTL_SERVER_DIR="$INSTL_N2N_DIR.server"
}
export INSTL_SERVER_DIR="$INSTL_N2N_DIR.server"

edge_install() {
    pkg_install n2n
    echo "-c=$N2N_COMMUNITY
-k=$N2N_KEY
-a=$N2N_ADDRESS
-l=$N2N_SUPERNODE_HOST:$N2N_SUPERNODE_PORT" > /etc/n2n/edge.conf
    systemctl enable edge --now
    match_replace_or_append /etc/cron.d/zw "^.+\brestart\s+edge\b.+$" "11 0-23/8 * * * root systemctl restart edge"
}

edge_uninstall() {
    rm -rfv /etc/cron.d/edge
    match_replace_or_append /etc/cron.d/zw "\brestart\s+edge\b"
    pkg_uninstall n2n
    systemctl daemon-reload
}

sa_install() {
    confirm_subj_env
    mkdir -p "$INSTL_SERVER_DIR"
    persistence_env "$INSTL_SERVER_DIR/.env" "N2N_SUPERNODE_PORT=$N2N_SUPERNODE_PORT"
    ! grep -sq "^$N2N_COMMUNITY$" "$INSTL_SERVER_DIR/community.list" && echo "$N2N_COMMUNITY" >> "$INSTL_SERVER_DIR/community.list"
    rewrite_to "$INSTL_SERVER_DIR/docker-compose.yml" "$SUBJ_RES_DIR/docker-compose.server.yml"
    docker compose -f "$INSTL_SERVER_DIR/docker-compose.yml" up -d
}

sa_uninstall() {
    docker compose -f "$INSTL_SERVER_DIR/docker-compose.yml" down
}

menu_route_or_rendor '
    ### The n2n management tool:
    --confirm-subj-env          confirm_subj_env
    --edge-install              edge_install
    --edge-uninstall            edge_uninstall
    --sa-install                sa_install              "Install supernode(docker)"
    --sa-uninstall              sa_uninstall            "Uninstall supernode(docker)"
    return "0. Return"
    ##1 choose a job:
' "$@"
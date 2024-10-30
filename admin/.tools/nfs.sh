#!/bin/bash

source "`dirname "$0"`/../../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$SYSTEM_DIR/lib.sh"

init_env() {
    try_load_env "$NFS_DIR/.preset.env"
    persistence_env "$SUBJ_ENV" "SHARE_ROOT=$APP_ROOT" \
        "NFS_DATA_PORT=`assemble_port $NFS_DATA_TOP_PORT`" \
        "NFS_RPC_PORT=`assemble_port $NFS_RPC_TOP_PORT`"
    try_load_env "$SUBJ_ENV"
    export INSTL_ADMIN_NFS="$INSTL_ADMIN_ROOT/nfs"
}

deploy() {
    init_env
    rewrite_to "$INSTL_ADMIN_NFS/.env" "$SUBJ_ENV"
    rewrite_to "$INSTL_ADMIN_NFS/docker-compose.yml" < <(sed -r "/(2049|111):/d" "$NFS_RES_DIR"/docker-compose.yml)
    [ -n "`docker compose -f "$INSTL_ADMIN_NFS/docker-compose.yml" top 2> /dev/null`" ] && undeploy
    docker compose -f "$INSTL_ADMIN_NFS/docker-compose.yml" up -d
    showmount
}

showmount() {
    try_load_env "$SUBJ_ENV"
    [ -z "$NFS_DATA_PORT" ] && return
    ip4_list="`get_ip4_list_local`"
    ip6_list="`get_ip6_list`"
    if [ -n "$ip4_list" ]; then
        echo "IPv4 might be:"
        echo "$ip4_list"
        echo "You can try using the following command to mount it:"
        echo "mount -t nfs //`echo "$ip4_list" | head -n 1`/share ./nfs -o port=$NFS_DATA_PORT"
    fi
    if [ -n "$ip6_list" ]; then
        echo "IPv6 might be:"
        echo "$ip6_list"
        echo "You can try using the following command to mount it:"
        echo "mount -t nfs //`echo "$ip6_list" | head -n 1`/share ./nfs -o port=$NFS_DATA_PORT"
    fi
}

undeploy() {
    init_env
    docker compose -f "$INSTL_ADMIN_NFS/docker-compose.yml" down
}

menu_route_or_rendor '
    --deploy        deploy
    --undeploy      undeploy
    --showmount     showmount
' "$@"
#!/bin/bash

source "`dirname "$0"`/../../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$SYSTEM_DIR/lib.sh"

init_env() {
    try_load_env "$SAMBA_DIR/.preset.env"
    check_confirm_envs "$SUBJ_ENV" "SHARE_NAME=${SHARE_NAME:-rapid-deployment}" \
        "SHARE_ROOT/=$APP_ROOT" \
        "SMB_ND_NETBIOS_PORT=`assemble_port $SMB_ND_NETBIOS_TOP_PORT`" \
        "SMB_ND_TCP_PORT=`assemble_port $SMB_ND_TCP_TOP_PORT`" \
        SMB_USER \
        SMB_PASS
    try_load_env "$SUBJ_ENV"
}

deploy() {
    init_env
    rewrite_to "$INSTL_ADMIN_SAMBA/.env" "$SUBJ_ENV"
    rewrite_to "$INSTL_ADMIN_SAMBA/docker-compose.yml" < <(sed -r "/(SHARE_USER_ROOT|445|139):/d" "$SAMBA_RES_DIR"/docker-compose.yml)
    rewrite_to "$INSTL_ADMIN_SAMBA/samba/config.yml" < <(envsubst < "$ADMIN_RES_DIR/samba.conf.yml")
    [ -n "`docker compose -f "$INSTL_ADMIN_SAMBA/docker-compose.yml" top 2> /dev/null`" ] && undeploy
    docker compose -f "$INSTL_ADMIN_SAMBA/docker-compose.yml" up -d
    showmount
}

showmount() {
    try_load_env "$SUBJ_ENV"
    [ -z "$SMB_ND_TCP_PORT" ] && return
    ip4_list="`get_ip4_list_local`"
    ip6_list="`get_ip6_list`"
    if [ -n "$ip4_list" ]; then
        echo "IPv4 might be:"
        echo "$ip4_list"
        echo "You can try using the following command to mount it:"
        echo "mount -t cifs //`echo "$ip4_list" | head -n 1`/$SHARE_NAME ./smb -o port=$SMB_ND_TCP_PORT,username=$SMB_USER,password=$SMB_PASS"
    fi
    if [ -n "$ip6_list" ]; then
        echo "IPv6 might be:"
        echo "$ip6_list"
        echo "You can try using the following command to mount it:"
        echo "mount -t cifs //`echo "$ip6_list" | head -n 1`/$SHARE_NAME ./smb -o port=$SMB_ND_TCP_PORT,username=$SMB_USER,password=$SMB_PASS"
    fi
}

undeploy() {
    init_env
    docker compose -f "$INSTL_ADMIN_SAMBA/docker-compose.yml" down
}

menu_route_or_rendor '
    --init-env      init_env
    --deploy        deploy
    --undeploy      undeploy
    --showmount     showmount
' "$@"
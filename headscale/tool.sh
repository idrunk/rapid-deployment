#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"
source "$SYSTEM_DIR/lib.sh"

confirm_subj_env() {
    check_confirm_envs "$SUBJ_ENV" \
        HEADSCALE_SYSTEM_USER \
        HEADSCALE_SERVER_HOST=${HEADSCALE_SERVER_HOST:-$BASE_DOMAIN} \
        HEADSCALE_SERVER_PORT=${HEADSCALE_SERVER_PORT:-`assemble_port $HEADSCALE_SERVER_TOP_PORT`} \
        HEADSCALE_METRICS_PORT=${HEADSCALE_METRICS_PORT:-`assemble_port $HEADSCALE_METRICS_TOP_PORT`} \
        HEADSCALE_GRPC_PORT=${HEADSCALE_GRPC_PORT:-`assemble_port $HEADSCALE_GRPC_TOP_PORT`}
    export SERVER_INSTL_DIR="$INSTL_SUBJ_DIR.server"
}
export SERVER_INSTL_DIR="$INSTL_SUBJ_DIR.server"

client_install() {
    mkdir -p "$INSTL_SUBJ_DIR/data"
    tar --strip-components 1 -C "$INSTL_SUBJ_DIR" -xzf "`label_to_pkg tailscale`"

    rewrite_to /etc/systemd/system/tailscaled.service < <(sed -re "/^EnvironmentFile=/d" -re "s|^(ExecStopPost=).+|\1$INSTL_SUBJ_DIR/tailscaled --cleanup|" \
        -re "s|^(ExecStart=).+|\1$INSTL_SUBJ_DIR/tailscaled --state=$INSTL_SUBJ_DIR/data/tailscaled.state|" "$INSTL_SUBJ_DIR/systemd/tailscaled.service")
    ln -sf "$INSTL_SUBJ_DIR/tailscale" /usr/local/bin/tailscale
    systemctl enable tailscaled --now
    [ -n "$HEADSCALE_SYSTEM_USER_PREAUTHKEY" ] && client_preauth_login "$HEADSCALE_SYSTEM_USER_PREAUTHKEY"
}

client_uninstall() {
    systemctl disable tailscaled --now
    rm -fv /usr/local/bin/tailscale /etc/systemd/system/tailscaled.service
    systemctl daemon-reload
}

client_preauth_login() {
    tailscale up --login-server "http://$HEADSCALE_SERVER_HOST:$HEADSCALE_SERVER_PORT" --authkey "$1"
    echo "Successful logged."
}

server_install() {
    confirm_subj_env
    rewrite_to "$SERVER_INSTL_DIR/.env" "$SUBJ_ENV"
    rewrite_to "$SERVER_INSTL_DIR/caddy/Caddyfile" "$SUBJ_RES_DIR/Caddyfile"
    rewrite_to "$SERVER_INSTL_DIR/headscale/config/config.yml" < <(envsubst < "$SUBJ_RES_DIR/config.yml.tpl")
    rewrite_to "$SERVER_INSTL_DIR/docker-compose.yml" "$SUBJ_RES_DIR/docker-compose.server.yml"
    docker compose -f "$SERVER_INSTL_DIR/docker-compose.yml" up -d
    server_waiting
    apikey="`server_gen_apikey "$UI_APIKEY"`"
    [ "$?" == "0" ] && persistence_env "$SUBJ_ENV" "HEADSCALE_UI_APIKEY=$apikey"
    server_add_user "$HEADSCALE_SYSTEM_USER"
    preauthkey="`server_create_preauthkey "$HEADSCALE_SYSTEM_USER"`"
    [ "$?" == "0" ] && persistence_env "$SUBJ_ENV" "HEADSCALE_SYSTEM_USER_PREAUTHKEY=$preauthkey"
    cat_subj_env
}

server_uninstall() {
    docker compose -f "$SERVER_INSTL_DIR/docker-compose.yml" down
    echo "Server uninstalled."
}

server_waiting() {
    while ! docker exec -it headscale headscale node ls 2> /dev/null | grep -qF MachineKey; do
        echo "Waiting for headscale ready."
        sleep 1
    done
}

server_gen_apikey() {
    apikey="$1"
    if [ -n "$apikey" ] && docker exec -it headscale headscale apikey ls | grep -qF "${apikey%%.*}"; then
        echo "$apikey"
        return
    fi
    docker exec -it headscale headscale apikey create
}

server_add_user() {
    user="$1"
    if docker exec -it headscale headscale users list | grep -qF "$user"; then
        echo "User already exists."
        return
    fi
    docker exec -it headscale headscale users create "$user"
}

server_create_preauthkey() {
    docker exec -it headscale headscale preauthkeys create -u "$1" -e 1d | grep -oP "^[0-9a-f]{32,}\b"
}

server_list_preauthkey() {
    docker exec -it headscale headscale preauthkeys ls -u "$1"
}

menu_route_or_rendor '
    ### The headscale management tool:
    --confirm-subj-env              confirm_subj_env
    --install                       client_install
    --uninstall                     client_uninstall
    --server-install                server_install                                      "Install headscale server(docker)"
    --server-uninstall              server_uninstall                                    "Uninstall headscale server(docker)"
    --client-preauth-login          "call_with_input_args client_preauth_login"         "Client preauth login"
    --server-gen-apikey             "call_with_input_args server_gen_apikey"            "Server gen apikey"
    --server-add-user               "call_with_input_args server_add_user"              "Server add user"
    --server-create-preauthkey      "call_with_input_args server_create_preauthkey"     "Server create preauthkey"
    --server-list-preauthkey        "call_with_input_args server_list_preauthkey"       "Server list preauthkeys"
                                    return                                              "0. Return to the parent menu"
    ##1 choose a job:
' "$@"
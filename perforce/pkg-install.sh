#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"

__init_env() {
    rewrite_to "$SUBJ_ENV" <<< "SERVICE_PORT=`assemble_port $SERVICE_TOP_PORT`"
    mkdir -p "$INSTL_SUBJ_DIR/data"
    useradd -UMs /usr/sbin/nologin $SERVICE_USER
    chown -R $SERVICE_USER:$SERVICE_USER "$INSTL_SUBJ_DIR"
}

__install() {
    tar -C "$INSTL_SUBJ_DIR" -xzf "`label_to_pkg helix-core-server`"
    rewrite_to /etc/systemd/system/perforce.service < <(envsubst < "$SUBJ_RES_DIR/perforce.service")
    systemctl enable perforce --now
    ln -sf "$INSTL_SUBJ_DIR/p4" /usr/local/bin/p4
    while ! p4 -p $SERVICE_PORT info 2>&1 | grep -q "Server uptime"; do
        echo "Waiting for perforce ready."
        sleep 1
    done
    p4 -p $SERVICE_PORT configure set dm.user.noautocreate=2
    p4 -p $SERVICE_PORT configure set security=4
    if [ "`os_like`" == rhel ]; then
        firewall-cmd --add-port $SERVICE_PORT/tcp --permanent --zone=public > /dev/null 2>&1
        firewall-cmd --reload
    fi
    echo "You can open p4v and use 'root' as name and set a password to login as the superuser."
}

__uninstall() {
    systemctl disable perforce --now
    rm -fv /usr/local/bin/p4 /etc/systemd/system/perforce.service
    systemctl daemon-reload
    userdel $SERVICE_USER
}

pkg_handle "$@"

#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"

__init_env() {
    check_confirm_envs "$SUBJ_ENV" \
        DOCKER_DATA_ROOT/ \
        DOCKER_HTTP_PROXY \
        DOCKER_HTTPS_PROXY \
        "DOCKER_REGISTRY_MIRRORS=${DOCKER_REGISTRY_MIRRORS:-https://docker.registry.cyou https://dockerpull.com/ https://docker.1panel.live}"
}

__install() {
    pkg_install container-selinux containerd.io docker-ce-cli docker-ce docker-compose-plugin docker-buildx-plugin docker-scan-plugin
    mirrors="${DOCKER_REGISTRY_MIRRORS:-https://docker.registry.cyou https://dockerpull.com/ https://docker.1panel.live}"
    rewrite_to /etc/docker/daemon.json <<EOF
{
    `[ -n "$DOCKER_DATA_ROOT" ] && echo '"data-root": "$DOCKER_DATA_ROOT",' | sed "s:\\$DOCKER_DATA_ROOT:$DOCKER_DATA_ROOT:"`
    `[ -n "$DOCKER_HTTP_PROXY" -a -n "$DOCKER_HTTPS_PROXY" ] && echo '"proxies": {
        "http-proxy": "$DOCKER_HTTP_PROXY",
        "https-proxy": "$DOCKER_HTTPS_PROXY"
    },' | sed -e "s:\\$DOCKER_HTTP_PROXY:$DOCKER_HTTP_PROXY:" -e "s:\\$DOCKER_HTTPS_PROXY:$DOCKER_HTTPS_PROXY:"`
    "registry-mirrors": [`xargs -n1 <<< "$mirrors" | sed -r 's/^|$/"/g' | paste -sd ","`]
}
EOF
    systemctl enable docker
    systemctl restart docker
}

__uninstall() {
    pkg_uninstall docker-scan-plugin docker-buildx-plugin docker-compose-plugin docker-ce docker-ce-cli containerd.io container-selinux
    rm -fv /etc/docker/daemon.json
    systemctl daemon-reload
}

pkg_handle "$@"
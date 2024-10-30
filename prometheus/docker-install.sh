#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    rewrite_to "$SUBJ_ENV" <<EOF
PROMETHUES_PORT=`assemble_port "$PROMETHUES_TOP_PORT"`
GRAFANA_PORT=`assemble_port "$GRAFANA_TOP_PORT"`
PROMETHUES_CONF_MARK=`confirm_dialog 'y/[n]' 'Apply kubernetes exporter?' && echo '-k8s'`
EOF
    mkdir -p "$INSTL_SUBJ_DIR"
    /bin/cp -rfv "$SUBJ_RES_DIR/"{grafana,prometheus} "$INSTL_SUBJ_DIR/"
}

docker_handle "$@"
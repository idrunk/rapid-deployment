#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    "$SUBJ_DIR/tool.sh" --confirm-subj-env
    rewrite_to "$INSTL_SUBJ_DIR/frp/frpc.toml" "$SUBJ_RES_DIR/frpc.toml" 
    rewrite_to "$INSTL_SUBJ_DIR/docker-compose.yml" "$SUBJ_RES_DIR/docker-compose.yml"
    try_load_env "$SUBJ_ENV"
    rewrite_to "$INSTL_SUBJ_DIR/frp/conf.d/local-ssh.toml" < <(envsubst < "$SUBJ_RES_DIR/local-ssh.toml.tpl")
}

docker_handle "$@"
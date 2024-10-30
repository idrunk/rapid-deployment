#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    check_confirm_envs "$SUBJ_ENV" \
        "SHARE_ROOT=${SHARE_ROOT:-$INSTL_SUBJ_DIR/nfs/data}" \
        "NFS_DATA_PORT=${NFS_DATA_PORT:-`assemble_port $NFS_DATA_TOP_PORT`}" \
        "NFS_RPC_PORT=${NFS_RPC_PORT:-`assemble_port $NFS_RPC_TOP_PORT`}"
}

docker_handle "$@"
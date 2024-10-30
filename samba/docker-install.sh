#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    "$SUBJ_DIR/tool.sh" --init-env
}

docker_handle "$@"
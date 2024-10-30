#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

__init_env() {
    rewrite_to "$SUBJ_ENV" <<EOF
HA_INIT_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
HA_WEB_PORT=`assemble_port $HA_WEB_TOP_PORT`
EOF
}

__after_install() {
    echo "The 'HA_INIT_PASSWD' you need to copy it and paste to the init page to finish the register."
}

docker_handle "$@"
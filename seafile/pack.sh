#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"
source "$LIB_DIR/docker-lib.sh"

__pack_dependent() {
    "$MYSQL80_DIR/pack.sh" "$@"
}

pack_handle "$@"

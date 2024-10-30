#!/bin/bash

create_network() {
    if [ -z "`docker network ls -qf name=zwnet`" ]; then
        docker network create zwnet
    fi
}

rm_network() {
    if [ -n "`docker network ls -qf name=zwnet`" ]; then
        docker network rm zwnet
    fi
}

case $1 in
    -cn) create_network
    ;;
    -rn) rm_network
    ;;
esac
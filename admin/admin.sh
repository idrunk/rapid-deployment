#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"

init_admin_env() {
    confirm_env "$SUBJ_ENV" INSTL_ADMIN_ROOT/
}

deploy() {
    init_admin_env
    "$SUBJ_DIR/.tools/${1:-samba}.sh" --deploy
}

undeploy() {
    "$SUBJ_DIR/.tools/${1:-samba}.sh" --undeploy
}

showmount() {
    "$SUBJ_DIR/.tools/samba.sh" --showmount
    "$SUBJ_DIR/.tools/nfs.sh" --showmount
}

menu_route_or_rendor "`cat <<EOF
    ### Select the sharing method:
    "try_echo_and ' ' '$SUBJ_DIR/.tools/winshare.sh'"       'Run windows share tool'
    deploy                                                  'Share the tool via samba'
    'deploy nfs'                                            'Share the tool via nfs'
    undeploy                                                'Undeploy the samba sharing'
    'undeploy nfs'                                          'Undeploy the nfs sharing'
    showmount                                               'Show the mount command sample'
    return                                                  '0. Return to the parent menu'
    ##1 Your select:
EOF
`" "$@"
#!/bin/bash

# $1: env file path
# $...: env var to check, exit 1 if check failed
try_load_env() {
    if [ -f "$1" ]; then
        mapfile -t assignments < <(sed -E "s/^\s+|\s+$|\r//g" "$1" | grep -vP "^((?=[^=]+[^\w=][^=]*=)[^=]+=|[^a-zA-Z]|[^=]*$)")
        export "${assignments[@]}"
    fi
    shift
    for var in "$@"; do
        if [ -z "${!var}" ]; then
            echo "Environment variable '$var' is not set." >&2
            exit 1
        fi
    done
}

cat_subj_env() {
    [ ! -f "$SUBJ_ENV" ] && return
    echo "Subject environment variables:"
    cat "$SUBJ_ENV"
}

# $1: env file path
# $...: "ENV_NAME=env value"
persistence_env() {
    [ $# -lt 2 ] && return
    env_file="$1"
    [ -f "$env_file" ] && envs="`cat "$env_file"`"
    shift
    export "$@"
    local IFS=$'\n' && new_envs="`echo "$*"`"
    branch_selector="`echo "$new_envs" | grep -oP "^\w+(?==)" | tr "\n" "|" | sed -E 's/\|$//'`"
    reserved="`echo "$envs" | grep -vP "^($branch_selector)"`"
    [ -n "$reserved" ] && reserved+=$'\n'
    reserved+="$new_envs"
    echo "$reserved" > "$env_file"
}

# $1: env file path
# $2: env key=?value, when the key end of '/', means value should be a directory; if value specified, it will be the default env value.
confirm_env() {
    env_file="$1"
    env_arg="$2"
    env_key="${env_arg%%=*}"
    [ "${env_key:0-1}" == "/" ] && value_type=directory || value_type=value
    env_key="${env_key/%\//}"
    [[ "$env_arg" == *=* ]] && default_val="${env_arg#*=}" || default_val=""
    default_env_val="${default_val:-${!env_key}}"
    read -p "$env_key[$default_env_val]: " input
    # must not exists if input specified, and must exists if not specified one
    if [ -n "$input" ]; then
        if [ "$value_type" == "directory" ]; then
            ! echo "$input" | grep -qn "^/" && input="`pwd`/$input"
            [ -e "$input" ] && ! confirm_dialog "y/[n]" "Path '$input' is already exists, are you sure you want use it?" && exit 1
            ! mkdir -p "$input" && exit 2
            input=`realpath "$input"`
            echo "Value of $env_key is '$input'"
        fi
        persistence_env "$env_file" "$env_key=$input"
        return
    fi
    [ -n "$default_env_val" -a "$value_type" == "directory" -a ! -d "$default_env_val" ] && \
        confirm_dialog "[y]/n" "$env_key '$default_env_val' not exists, want to autocreate?" && mkdir -p "$default_env_val"
    [ -n "$default_val" ] && persistence_env "$env_file" "$env_key=$default_val"
}

confirm_envs() {
    env_file="$1"
    shift
    for env_arg in "$@"; do
        confirm_env "$env_file" "$env_arg"
    done
}

check_confirm_envs() {
    envfile="$1"
    [[ "$2" == -* ]] && flag="$2" || flag=""
    if [ -f "$envfile" ]; then
        # directly return if the test is exists or subj_env is newer than the lib_env
        [ "$flag" == "--exist" -o `stat -c %Y "$envfile"` -ge `stat -c %Y "$LIB_DIR/.env"` ] && return
        cat "$envfile" 2> /dev/null
        if ! confirm_dialog "y/[n]" "Need to modify these envs?"; then
            touch -m "$envfile" # touch the env if no need modify
            return
        fi
    fi
    shift
    [ -n "$flag" ] && shift
    confirm_envs "$envfile" "$@"
    return 1
}

build_instl_subj_envs() {
    export INSTL_SUBJ_DIR="$INSTL_ROOT/$SUBJ_NAME"
    export INSTL_SUBJ_LOCK="$INSTL_SUBJ_DIR/.lock"
    for tuple in "${SUBJ_NAMES[@]}"; do
        tuple=(${tuple[@]})
        export "INSTL_${tuple[1]}_DIR=$INSTL_ROOT/${tuple[0]}"
    done
}

export SUBJ_DIR="`dirname "$(realpath "$0")"`"
while [[ ! -d "`dirname "$SUBJ_DIR"`/.libs" ]]; do
    export SUBJ_DIR="`dirname "$SUBJ_DIR"`"
done
export SUBJ_RES_DIR="$SUBJ_DIR/.res"
export SUBJ_NAME="`basename "$SUBJ_DIR"`"
export SUBJ_ENV="$SUBJ_DIR/.env"
export APP_ROOT="`dirname "$SUBJ_DIR"`"
export LIB_DIR="$APP_ROOT/.libs"
try_load_env "$SUBJ_DIR/.preset.env"
try_load_env "$SUBJ_ENV"
try_load_env "$LIB_DIR/.env"

# auto generate subject environment variable
SUBJ_NAMES=()
for name in `find "$APP_ROOT" -maxdepth 1 -mindepth 1 -type d ! -name .libs | grep -oP "[^/]+$"`; do
    upper_name="`echo "$name" | sed -e 's/\.//g' -e 's/-/_/g' -e 's/.*/\U&/g'`"
    SUBJ_NAMES+=("$name $upper_name")
    export "${upper_name}_DIR=$APP_ROOT/$name"
    export "${upper_name}_RES_DIR=$APP_ROOT/$name/.res"
done
build_instl_subj_envs

# echo "$SUBJ_DIR"
# echo "$SUBJ_NAME"
# echo "$APP_ROOT"
# echo "$LIB_DIR"

# echo "$INSTL_ROOT"
# echo "$INSTL_SUBJ_DIR"

# echo "$SYSTEM_DIR"
# echo "$SYSTEM_DIR"
# echo "$INSTL_SYSTEM_DIR"

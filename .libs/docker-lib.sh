label_to_img() {
    echo "$LIB_DIR/.images/$(echo "$1" | tr "/" "-" | tr ":" "#")"
}

docker_image_list() {
    find "$SUBJ_DIR" -name docker-image.list -exec sh -c "envsubst < '{}' | grep -v ^\s*$ | sed 's/\r//'" \;
}

docker_pull_save() {
    image="$1"
    target="`label_to_img "$image"`"
    if [ -e "$target" ]; then
        echo "File "$target" was already exists, will not be saved as"
        return 0
    fi
    docker pull $image
    echo "Image '$image' is being saved to '$target'"
    docker image save $image -o "$target"
}

docker_pull_save_list() {
    # `grep -v ^$`: delete empty line and append break in end of stream
    docker_image_list | while read img; do
        docker_pull_save "$img"
    done
}

docker_remove_pkg_list() {
    docker_image_list | while read img; do
        rm -fv "`label_to_img "$img"`"
    done
}

# $1: $pack_target_root
docker_pack_list_to() {
    packages_target="$1/.libs/.images/"
    docker_image_list | while read img; do
        /bin/cp -rnv "`label_to_img "$img"`" "$packages_target"
    done
}

docker_load() {
    image="$1"
    target="`label_to_img "$image"`"
    if [ -n "`docker image ls -qf reference=$image`" ]; then
        echo "Image '$image' was already exists, will not be loaded"
        return 0
    fi
    echo "File '$target' will be loaded as image '$image'"
    docker image load -i "$target"
}

docker_load_list() {
    docker_image_list | while read img; do
        docker_load "$img"
    done
}

docker_rmi() {
    image="$1"
    if [ -z "`docker image ls -qf reference=$image`" ]; then
        echo "Image '$image' not found, will no longer continue to remove"
        return 0
    fi
    echo "Image '$image' is being deleted"
    docker rmi -f $image
}

docker_rmi_list() {
    docker_image_list | while read img; do
        docker_rmi "$img"
    done
}

docker_copy_to() {
    [[ "$1" == -* ]] && flag="$1" || flag=""
    src_file="${2:-$1}"
    rewrite_to "$INSTL_SUBJ_DIR/docker-compose.yml" "${src_file:-$SUBJ_RES_DIR/docker-compose.yml}" $flag
}

docker_install() {
    docker compose -f "$INSTL_SUBJ_DIR/docker-compose.yml" up -d
}

docker_uninstall() {
    docker compose -f "$INSTL_SUBJ_DIR/docker-compose.yml" down
}

docker_mapping_mod() {
    instl_subj_dir="$1" # ports, volumes
    part="$2" # ports, volumes
    remove="$3"
    shift
    [ "$remove" == "-rm" ] && shift
    for mapping in "$@"; do
        if [ "$remove" == "-rm" ]; then
            sed -ri "/$mapping/d" "$instl_subj_dir/docker-compose.yml"
        else
            ! grep -Fq "$mapping" "$instl_subj_dir/docker-compose.yml" && sed -ri "/$part:/a \      - $mapping" "$instl_subj_dir/docker-compose.yml"
        fi
    done
}

docker_handle() {
    case "$1" in
    "--init-env")
        [ -e "$INSTL_SUBJ_LOCK" ] && return
        docker_load_list
        func_exists __docker_copy_to && __docker_copy_to || docker_copy_to
        func_exists __init_env && __init_env
        [ -f "$SUBJ_ENV" ] && rewrite_to "$INSTL_SUBJ_DIR/.env" "$SUBJ_ENV"
    ;;
    "--install")
        func_exists __before_install && __before_install
        docker_install
        func_exists __after_install && __after_install
        cat_subj_env
        touch "$INSTL_SUBJ_LOCK"
    ;;
    "--uninstall")
        func_exists __before_uninstall && __before_uninstall
        docker_uninstall
        func_exists __after_uninstall && __after_uninstall
        rm -rfv "$INSTL_SUBJ_LOCK"
    ;;
    "--clear-data")
        if [ -e "$INSTL_SUBJ_LOCK" ]; then
            echo "Subject '$SUBJ_NAME' was locked, please uninstall first then do clear." >&2
            return 1
        fi
        func_exists __clear_data && __clear_data || subj_clear
    ;;
    "--rmi")
        docker_rmi_list
    ;;
    esac
}


k8s_load() {
    image="$1"
    target="`label_to_img "$image"`"
    if ctr -n k8s.io i ls -q | grep -q "$image"; then
        echo "Kubernetes image '$image' was already exists, will not be loaded"
        return 0
    fi
    echo "File '$target' will be loaded as kubernetes image '$image'"
    ctr -n k8s.io i import "$target"
}

k8s_load_list() {
    docker_image_list | while read img; do
        k8s_load "$img"
    done
}
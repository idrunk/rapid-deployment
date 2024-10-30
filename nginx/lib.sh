nginx_conf_mod() {
    target="$INSTL_NGINX_DIR/nginx/conf.d/$1"
    shift
    rewrite_to "$target" "$@"
}

nginx_docker_mapping_mod() {
    docker_mapping_mod "$INSTL_NGINX_DIR" "$@"
}
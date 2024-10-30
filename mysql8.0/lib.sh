docker_mysql_waiting() {
    try_load_env "$INSTL_MYSQL80_DIR/.env"
    while ! docker exec -i -e MYSQL_PWD=$MYSQL_ROOT_PASS mysql80 sh -c "mysql -uroot <<< 'show databases' 2> /dev/null" | grep -qF Database; do
        echo "Waiting for mysql ready."
        sleep 5
    done
}

docker_mysql_exec() {
    docker_mysql_waiting
    docker exec -i -e MYSQL_PWD=$MYSQL_ROOT_PASS mysql80 mysql -uroot < "$INSTL_MYSQL80_DIR/mysql/initdb.d/$1"
}

docker_mysql_query() {
    docker_mysql_waiting
    docker exec -i -e MYSQL_PWD=$MYSQL_ROOT_PASS mysql80 mysql -uroot -e "$1"
}

mysql_initdb_mod() {
    target="$INSTL_MYSQL80_DIR/mysql/initdb.d/$1"
    shift
    rewrite_to "$target" "$@"
}
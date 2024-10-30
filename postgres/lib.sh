docker_postgres_waiting() {
    try_load_env "$INSTL_POSTGRES_DIR/.env"
    while ! docker exec -t -e PGPASSWORD=$POSTGRES_PASSWORD postgres sh -c "psql -Upostgres -c 'select datname from pg_database' 2> /dev/null" | grep -q postgres; do
        echo "Waiting for postgres ready."
        sleep 5
    done
}

docker_postgres_exec() {
    docker_postgres_waiting
    docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD postgres psql -Upostgres < "$INSTL_POSTGRES_DIR/postgres/initdb.d/$1"
}

docker_postgres_query() {
    docker_postgres_waiting
    docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD postgres psql -Upostgres -c "$1"
}

postgres_initdb_mod() {
    target="$INSTL_POSTGRES_DIR/postgres/initdb.d/$1"
    shift
    rewrite_to "$target" "$@"
}

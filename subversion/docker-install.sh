#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/docker-lib.sh"
source "$SYSTEM_DIR/lib.sh"
source "$MYSQL80_DIR/lib.sh"

__init_env() {
    "$MYSQL80_DIR/docker-install.sh" --init-env
    rewrite_to "$SUBJ_ENV" <<EOF
SA_DB_HOST=mysql80
SA_DB_NAME=svnadmin
SA_DB_USER=svnadmin
SA_DB_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
SA_ADMIN_USER=svnadmin
SA_ADMIN_PASSWD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
SA_PORT=`assemble_port $SA_TOP_PORT`
SA_WEB_PORT=`assemble_port $SA_WEB_TOP_PORT`
EOF

    docker run --rm --name svnadmin -d witersencom/svnadmin:2.5.9 /usr/sbin/init
    mkdir -p "$INSTL_SUBJ_DIR/svnadmin"
    docker cp svnadmin:/var/www/html "$INSTL_SUBJ_DIR/svnadmin/app"
    docker cp svnadmin:/home/svnadmin "$INSTL_SUBJ_DIR/svnadmin/data"
    docker cp svnadmin:/etc/httpd/conf.d "$INSTL_SUBJ_DIR/svnadmin/conf.d"
    docker cp svnadmin:/etc/sasl2 "$INSTL_SUBJ_DIR/svnadmin/sasl2"
    docker stop svnadmin
}

__before_install() {
    "$MYSQL80_DIR/docker-install.sh" --install
    docker_mysql_query "show databases" | grep -Fq svnadmin && return
    rewrite_to "$INSTL_SUBJ_DIR/svnadmin/app/config/database.php" < <(envsubst < "$SUBJ_RES_DIR/database.php")
    mysql_initdb_mod svnadmin.sql.txt <<EOF
`envsubst < "$SUBJ_RES_DIR/svnadmin.sql.txt.tpl"`
`sed -r "/INSERT INTO .admin_users\b.+/ s/admin(',\s*')admin/$SA_ADMIN_USER\1$SA_ADMIN_PASSWD/" "$INSTL_SUBJ_DIR/svnadmin/app/templete/database/mysql/svnadmin.sql"`
EOF
    docker_mysql_exec svnadmin.sql.txt
}

__after_install() {
    while ! docker logs svnadmin -n 20 | grep -Fq "(svnadmind)启动成功"; do
        echo "Waiting for svnadmin ready."
        sleep 2
    done
    docker exec -t svnadmin chown -R apache:apache /home/svnadmin
}

__clear_data() {
    mysql_initdb_mod svnadmin.sql.txt
    subj_clear
}

docker_handle "$@"
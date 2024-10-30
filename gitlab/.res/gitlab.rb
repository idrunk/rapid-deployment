gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"
gitlab_rails['db_password'] = "$GL_DB_PASSWD"
gitlab_rails['db_host'] = "$GL_DB_HOST"
postgresql['enable'] = false
nginx['listen_port'] = $GL_WEB_PORT
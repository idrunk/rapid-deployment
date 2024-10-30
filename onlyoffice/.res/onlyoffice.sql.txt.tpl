CREATE DATABASE IF NOT EXISTS onlyoffice;
DROP USER IF EXISTS '${OO_DB_USER}'@'%';
CREATE USER '${OO_DB_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${OO_DB_PASS}';
GRANT ALL PRIVILEGES ON onlyoffice.* TO '${OO_DB_USER}'@'%';
FLUSH PRIVILEGES;
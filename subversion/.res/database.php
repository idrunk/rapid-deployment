<?php
/*
 * @Author: witersen
 *
 * @LastEditors: witersen
 *
 * @Description: QQ:1801168257
 */

/**
 * for MySQL
 * config from Medoo 1.7.10
 */
return [
    'database_type' => 'mysql',
    'server' => '$SA_DB_HOST',
    'database_name' => '$SA_DB_NAME',
    'username' => '$SA_DB_USER',
    'password' => '$SA_DB_PASSWD',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_general_ci',
    'port' => 3306,
    'prefix' => '',
    'logging' => false,
    'option' => [
        PDO::ATTR_CASE => PDO::CASE_NATURAL
    ],
    'command' => [
        'SET SQL_MODE=ANSI_QUOTES'
    ]
];

/**
 * for SQLite
 * config from Medoo 1.7.10
 *
 * %s 为占位符 无需修改
 */

// return [
//     'database_type' => 'sqlite',
//     'database_file' => '%ssvnadmin.db'
// ];

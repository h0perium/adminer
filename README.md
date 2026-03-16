# Adminer 5.4.2 (stable) + default DB drivers + MongoDB + Firebird

## Why you saw the MySQL extension error
Adminer can only connect to a DB system if the corresponding PHP extension exists. If no MySQL extension is loaded, Adminer shows:
> None of the supported PHP extensions (MySQLi, MySQL, PDO_MySQL) are available.

This image includes the default DB extensions:
- mysqli + pdo_mysql
- pdo_pgsql
- pdo_sqlite
- pdo_odbc
- pdo_dblib
- pdo_firebird

Plus:
- mongodb (PECL) + the Adminer MongoDB driver plugin
- Firebird (PDO) custom driver plugin for dropdown

## Build
```bash
docker build -t adminer-full:5.4.2 .
```

## Run
```bash
# safer for testing (avoid conflicting with existing services on port 80)
docker run -d --name adminer -p 8080:80 adminer-full:5.4.2
```

## Verify
```bash
docker exec -it adminer php -m | egrep 'mysqli|pdo_mysql|pdo_pgsql|pdo_sqlite|pdo_dblib|pdo_odbc|pdo_firebird|mongodb'
```

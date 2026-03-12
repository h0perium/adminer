# Universal Adminer Docker Container

A lightweight, all-in-one Docker image for [Adminer](https://www.adminer.org/) with support for multiple databases.  
Includes PHP-FPM, Nginx, and PHP extensions for MySQL/MariaDB, PostgreSQL, SQLite, SQL Server (via FreeTDS), MongoDB, Redis, and optional Firebird.  
PHP-FPM uses a Unix socket for fast internal communication.

---

## Features

- PHP 8.2 FPM + Nginx
- Unix socket (`.sock`) between Nginx and PHP-FPM (efficient, no TCP overhead)
- Supports multiple databases:
  - MySQL / MariaDB (`pdo_mysql`)
  - PostgreSQL (`pdo_pgsql`)
  - SQLite (`pdo_sqlite`)
  - SQL Server (`pdo_dblib` / FreeTDS)
  - MongoDB (PECL)
  - Redis (PECL)
  - Optional Firebird (`pdo_firebird`)
- Adminer plugins automatically included:
  - MySQL, PostgreSQL, SQLite, MongoDB, Firebird
- Lightweight and fully Alpine-based

---

## Build

Clone this repository (or copy the Dockerfile) and build the image:

```bash
git clone https://github.com/h0perium/adminer.git
cd adminer
docker build -t adminer-universal .

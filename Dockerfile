# ============================================
# Universal Adminer Container — Alpine 3.18+
# PHP-FPM + Nginx using Unix Socket
# ============================================

FROM php:8.2-fpm-alpine

# --------------------------------------------
# System dependencies (build + runtime)
# --------------------------------------------
RUN apk add --no-cache \
    nginx \
    curl \
    icu-dev \
    unixodbc-dev \
    freetds-dev \
    postgresql-dev \
    mariadb-connector-c-dev \
    sqlite-dev \
    bash \
    $PHPIZE_DEPS

# Optional Firebird support (edge/testing repo)
# RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing firebird-dev

# --------------------------------------------
# Core PHP extensions
# --------------------------------------------
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    intl \
    pdo_dblib

# Optional Firebird extension
# RUN docker-php-ext-install pdo_firebird

# --------------------------------------------
# PECL extensions
# --------------------------------------------
RUN pecl install mongodb redis \
    && docker-php-ext-enable mongodb redis

# --------------------------------------------
# Adminer setup
# --------------------------------------------
WORKDIR /var/www/html

RUN curl -L https://www.adminer.org/latest-en.php -o adminer.php
RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/plugins/plugin.php -o plugin.php
RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/plugins/drivers/mysql.php -o mysql.php
RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/plugins/drivers/pgsql.php -o pgsql.php
RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/plugins/drivers/sqlite.php -o sqlite.php
RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/plugins/drivers/mongo.php -o mongo.php
RUN curl -L https://raw.githubusercontent.com/vrana/adminer/master/plugins/drivers/firebird.php -o firebird.php

# --------------------------------------------
# Adminer entrypoint (plugin loader)
# --------------------------------------------
RUN cat <<'EOF' > index.php
<?php
require 'plugin.php';

function adminer_object() {
    return new AdminerPlugin([
        new AdminerMysqlDriver(),
        new AdminerPgsqlDriver(),
        new AdminerSqliteDriver(),
        new AdminerMongoDriver(),
        new AdminerFirebirdDriver()
    ]);
}

include 'adminer.php';
EOF

# --------------------------------------------
# PHP-FPM configuration to use Unix socket
# --------------------------------------------
RUN mkdir -p /usr/local/etc/php-fpm.d \
    && cat <<'EOF' > /usr/local/etc/php-fpm.d/www.conf
[www]
user = nobody
group = nobody
listen = /var/run/php-fpm.sock
listen.owner = nobody
listen.group = nobody
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF

# Ensure socket directory exists
RUN mkdir -p /var/run

# --------------------------------------------
# Nginx configuration (use PHP-FPM socket)
# --------------------------------------------
RUN rm /etc/nginx/http.d/default.conf && \
    cat <<'NGINXCONF' > /etc/nginx/http.d/default.conf
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.php;

    location / {
        try_files $uri /index.php;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
NGINXCONF

# --------------------------------------------
# Expose port
# --------------------------------------------
EXPOSE 80

# --------------------------------------------
# Start PHP-FPM and Nginx (JSON array form)
# --------------------------------------------
CMD ["sh", "-c", "php-fpm && nginx -g 'daemon off;'"]

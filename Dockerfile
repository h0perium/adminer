# Adminer 5.4.2 (stable) - single container (Apache + PHP)
# Includes the *default* SQL database extensions (MySQL/MariaDB, PostgreSQL, SQLite, MS SQL) 
# PLUS MongoDB (PECL) + Firebird (PDO_FIREBIRD with custom driver plugin to show in dropdown).
#
# Why: Adminer can only offer a DB system if the corresponding PHP extension is available.
# If MySQL extensions are missing, Adminer shows: "None of the supported PHP extensions (MySQLi, MySQL, PDO_MySQL) are available."

FROM php:8.4-apache

ARG ADMINER_VERSION=5.4.2

# Bake plugin defaults into the image (no need to pass at runtime)
ENV ADMINER_PLUGINS="tables-filter json-column dump-json dump-zip foreign-system pretty-json-column" \
    ADMINER_DESIGN=""

# Build deps for PHP extensions
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      # PostgreSQL
      libpq-dev \
      # SQLite
      libsqlite3-dev \
      # ODBC (for pdo_odbc)
      unixodbc-dev \
      # MS SQL / Sybase (for pdo_dblib)
      freetds-dev \
      # Firebird (for pdo_firebird)
      firebird-dev \
      libfbclient2 \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install default DB extensions
RUN set -eux; \
    docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr; \
    docker-php-ext-install -j"$(nproc)" \
      mysqli \
      pdo_mysql \
      pdo_pgsql \
      pdo_sqlite \
      pdo_odbc \
      pdo_dblib \
      pdo_firebird

# MongoDB extension (PECL)
RUN set -eux; \
    pecl channel-update pecl.php.net; \
    pecl install mongodb; \
    docker-php-ext-enable mongodb

# Download Adminer + bundled plugins/designs
RUN set -eux; \
    mkdir -p /var/www/html/plugins-enabled /var/www/html/plugins /var/www/html/designs /opt/adminer-src; \
    curl -fsSL "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php" -o /var/www/html/adminer.php; \
    curl -fsSL "https://github.com/vrana/adminer/archive/v${ADMINER_VERSION}.tar.gz" -o /tmp/source.tar.gz; \
    tar xzf /tmp/source.tar.gz -C /opt/adminer-src --strip-components=1 "adminer-${ADMINER_VERSION}/designs/" "adminer-${ADMINER_VERSION}/plugins/"; \
    cp -a /opt/adminer-src/plugins/* /var/www/html/plugins/; \
    cp -a /opt/adminer-src/designs/* /var/www/html/designs/; \
    rm -rf /tmp/source.tar.gz /opt/adminer-src

# Custom Firebird PDO driver plugin (so Firebird appears in dropdown without legacy interbase/ibase)
COPY plugins/drivers/firebird-pdo.php /var/www/html/plugins/drivers/firebird-pdo.php

# Adminer bootstrap + plugin loader
COPY index.php /var/www/html/index.php
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]

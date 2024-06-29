#!/bin/sh

apk add php82-fpm \
php82-session \
php82-soap \
php82-openssl \
php82-gmp \
php82-pdo_odbc \
php82-json \
php82-dom \
php82-pdo \
php82-zip \
php82-mysqli \
php82-sqlite3 \
php82-apcu \
php82-pdo_pgsql \
php82-bcmath \
php82-gd \
php82-odbc \
php82-pdo_mysql \
php82-pdo_sqlite \
php82-gettext \
php82-xmlreader \
php82-bz2 \
php82-iconv \
php82-pdo_dblib \
php82-curl \
php82-ctype \
php82-intl \
php82-mbstring \
php82-xml \
php82-simplexml \
php82-cli

rc-update add php-fpm82 default

rm /www/index.html
  cat << EOF > /www/index.php
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>HTML5</title>
    </head>
    <body>
        Server is online.

        <hr>

        <?php phpinfo( ); ?>
    </body>
    </html>
EOF

PHP_FPM_USER="www"
PHP_FPM_GROUP="www"
PHP_FPM_LISTEN_MODE="0660"
PHP_MEMORY_LIMIT="512M"
PHP_MAX_UPLOAD="50M"
PHP_MAX_FILE_UPLOAD="200"
PHP_MAX_POST="100M"
PHP_DISPLAY_ERRORS="On"
PHP_DISPLAY_STARTUP_ERRORS="On"
PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
PHP_CGI_FIX_PATHINFO=0


# Modifying configuration file www.conf
sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php82/php-fpm.d/www.conf
sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php82/php-fpm.d/www.conf
sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php82/php-fpm.d/www.conf
sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php82/php-fpm.d/www.conf
sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php82/php-fpm.d/www.conf
sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php82/php-fpm.d/www.conf #uncommenting line

# Modifying configuration file php.ini
sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php82/php.ini
sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php82/php.ini
sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php82/php.ini
sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php82/php.ini
sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php82/php.ini
sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php82/php.ini
sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php82/php.ini
sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php82/php.ini


# To add PHP support to Nginx we should modify Nginx configuration file:
cat << EOF > /etc/nginx/nginx.conf
user                            www;
worker_processes                1;

error_log                       /var/log/nginx/error.log warn;
pid                             /var/run/nginx/nginx.pid;

events {
    worker_connections          1024;
}

http {
    include                     /etc/nginx/mime.types;
    default_type                application/octet-stream;
    sendfile                    on;
    access_log                  /var/log/nginx/access.log;
    keepalive_timeout           3000;
    server {
        listen                  80;
        root                    /www;
        index                   index.html index.htm index.php;
        server_name             localhost;
        client_max_body_size    32m;
        error_page              500 502 503 504  /50x.html;
        location = /50x.html {
              root              /var/lib/nginx/html;
        }
        location ~ \.php$ {
              fastcgi_pass      127.0.0.1:9000;
              fastcgi_index     index.php;
              include           fastcgi.conf;
        }
    }
}
EOF


# Timezone
apk add tzdata
TIMEZONE="Europe/Amsterdam"
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" > /etc/timezone
sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php82/php.ini

rc-service php-fpm82 start
rc-service nginx restart

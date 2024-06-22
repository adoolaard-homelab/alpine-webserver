#!/bin/sh

# Controleer root privileges
if [ $(whoami) != "root" ]; then
  echo "Dit script moet als root worden uitgevoerd."
  exit 1
fi

# Update pakkettenlijst
apk update

# Installeer Nginx
apk add nginx
adduser -D -g 'www' www
mkdir /www
ln -s /www /root/website
chown -R www:www /var/lib/nginx
chown -R www:www /www
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
touch /etc/nginx/nginx.conf
cat << EOF > /etc/nginx/nginx.conf
user                            www;
worker_processes                auto; # it will be determinate automatically by the number of core

error_log                       /var/log/nginx/error.log warn;
#pid                             /var/run/nginx/nginx.pid; # it permit you to use rc-service nginx reload|restart|stop|start

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
        index                   index.html index.htm;
        server_name             localhost;
        client_max_body_size    32m;
        error_page              500 502 503 504  /50x.html;
        location = /50x.html {
              root              /var/lib/nginx/html;
        }
    }
}
EOF

cat << EOF > /www/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>HTML5</title>
</head>
<body>
    Server is online. Installatie zonder php.
</body>
</html>
EOF


# Stel Nginx in als default webserver
rc-update add nginx default
rc-service nginx start

# Optionele installatie van GIT
echo "GIT installeren? (y/n)"
read install_git
if [ "$install_git" = "y" ]; then
	apk add git
fi


# Optionele installatie van PHP 8.2
echo "PHP 8.2 installeren? (y/n)"
read install_php

if [ "$install_php" = "y" ]; then
  # apk add php82 php82-cli php82-fpm php82-mbstring php82-xml php82-gd php82-json
	apk add php82-fpm php82-session php82-soap php82-openssl php82-gmp php82-pdo_odbc php82-json php82-dom php82-pdo php82-zip php82-mysqli php82-sqlite3 php82-apcu php82-pdo_pgsql php82-bcmath php82-gd php82-odbc php82-pdo_mysql php82-pdo_sqlite php82-gettext php82-xmlreader php82-bz2 php82-iconv php82-pdo_dblib php82-curl php82-ctype php82-intl php82-mbstring php82-xml php82-simplexml php82-cli

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

fi

# Optionele installatie van MariaDB
echo "MariaDB installeren? (y/n)"
read install_mariadb

if [ "$install_mariadb" = "y" ]; then
  #apk add mariadb-client mariadb-server
  # apk add mysql mysql-client
  apk add mariadb mariadb-client

  rc-service mariadb setup
  rc-update add mariadb default
  rc-service mariadb start

  # De standaard mysql dingen  
  echo "Gaat nu de standaard dingen voor mariadb vragen"
  mysql_secure_installation
  rc-service mariadb restart

  # Database configureren
  echo "Database naam:"
  read db_name
  echo "Database wachtwoord:"
  read db_pass

  mariadb -e "CREATE DATABASE ${db_name} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
  mariadb -e "CREATE USER ${db_name}@localhost IDENTIFIED BY '${db_pass}';"
  mariadb -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_name}'@'localhost';"
  mariadb -e "FLUSH PRIVILEGES;"

  rc-service mariadb restart
fi


# Optionele installatie van SQLite
echo "SQLite installeren? (y/n)"
read install_sqlite
if [ "$install_sqlite" = "y" ]; then
	apk add sqlite
fi


# Overzicht van geïnstalleerde pakketten
echo "Geïnstalleerde pakketten:"
echo "nginx"

if [ "$install_php" = "y" ]; then
	echo "php 8.2"
fi

# Databasegegevens (indien geïnstalleerd)
if [ "$install_mariadb" = "y" ]; then
  echo "MariaDB database:"
  echo "Naam: $db_name"
  echo "Gebruiker: $db_name"
  echo "Wachtwoord: $db_pass"
fi


if [ "$install_sqlite" = "y" ]; then
	echo "Sqlite"
fi

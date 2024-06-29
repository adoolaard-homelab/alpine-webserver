#!/bin/sh

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
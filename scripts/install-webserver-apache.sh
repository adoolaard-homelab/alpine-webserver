#!/bin/sh

# Install Apache
apk add apache2
rc-service apache2 start
rc-update add apache2
rc-service apache2 restart

# Check if PHP-FPM should be installed
if [ "$install_php82" = "y" ]; then
    # Install Apache proxy module and PHP-FPM
    apk add apache2-proxy

    # Configure Apache to use PHP-FPM
    sed -i 's/^#LoadModule mpm_event_module/LoadModule mpm_event_module/' /etc/apache2/httpd.conf
    sed -i 's/^LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/' /etc/apache2/httpd.conf

    cat >> /etc/apache2/httpd.conf << EOF
<FilesMatch \.php$>
    SetHandler "proxy:fcgi://127.0.0.1:9000"
</FilesMatch>
EOF

    # Disable PHP module in Apache
    sed -i 's/^LoadModule php_module/#LoadModule php_module/' /etc/apache2/conf.d/php8-module.conf
    sed -i 's/^DirectoryIndex index.php index.html/#DirectoryIndex index.php index.html/' /etc/apache2/conf.d/php8-module.conf
    sed -i 's/^<FilesMatch \.php$>/#<FilesMatch \.php$>/' /etc/apache2/conf.d/php8-module.conf
    sed -i 's/^ *SetHandler application\/x-httpd-php/# &/' /etc/apache2/conf.d/php8-module.conf
    sed -i 's/^<\/FilesMatch>/#<\/FilesMatch>/' /etc/apache2/conf.d/php8-module.conf

    # Configure PHP-FPM
    sed -i 's/^user = nobody/user = apache/' /etc/php8/php-fpm.d/www.conf
    sed -i 's/^group = nobody/group = apache/' /etc/php8/php-fpm.d/www.conf

    # Restart services to apply changes
    rc-service php-fpm8 reload
    rc-service apache2 reload
fi
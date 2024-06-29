#!/bin/sh

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
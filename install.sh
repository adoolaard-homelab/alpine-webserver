#!/bin/sh


# ---------- INITIALISATIE ----------
# Controleer root privileges
if [ $(whoami) != "root" ]; then
  echo "Dit script moet als root worden uitgevoerd."
  exit 1
fi

# Controleer of GIT is geïnstalleerd, zo niet installeer het
if [ ! -x "$(command -v git)" ]; then
  echo "Git is niet geïnstalleerd. Installeren..."
  apk add git
fi

# Update pakkettenlijst
apk update


# ---------- PHP ----------
echo "Do you want to install PHP 8.2? (y/n)"
read install_php82
if [ "$install_php82" = "y" ]; then
  sh ./scripts/install-php82.sh
fi


# ---------- WEBSERVER ----------
# Een select menu in welke ik kan kiezen tussen apache of nginx
echo "Kies tussen apache of nginx"
echo "1) Apache (beta)"
echo "2) Nginx (stable)"
read webserver
if [ "$webserver" = "1" ]; then
    sh ./scripts/install-webserver-apache.sh
elif [ "$webserver" = "2" ]; then
    sh ./scripts/install-webserver-nginx.sh
fi




# ---------- DATABASE ----------
echo "Choose between mariadb, sqlite or none"
echo "1) MariaDB"
echo "2) SQLite"
echo "3) None"
read database
if [ "$database" = "1" ]; then
  sh ./scripts/install-database-mariadb.sh
elif [ "$database" = "2" ]; then
  apk add sqlite
else
  echo "No database selected. Continuing..."
fi


# ---------- OVERVIEW ----------
echo "Installed packages:"
if [ "$webserver" = "1" ]; then
  echo "apache2"
elif [ "$webserver" = "2" ]; then
  echo "nginx"
fi

if [ "$install_php" = "y" ]; then
	echo "php 8.2"
fi

if [ "$database" = "1" ]; then
  echo "MariaDB"
elif [ "$database" = "2" ]; then
  echo "SQLite"
else
  echo "No database installed"
fi
#!/bin/bash

# Check if the script is being run as superuser
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be executed with superuser privileges. Please run it again with sudo." 
    exit 1
fi

# Update package list and upgrade all packages
apt update
apt -y upgrade

# Install MariaDB server and perform security configuration
apt -y install mariadb-server
mysql_secure_installation

# Prompt the user for the MariaDB database password
read -sp "Enter the MariaDB database password: " db_password

# Create the GLPI database, a user, and grant permissions
mysql -u root -p$db_password <<MYSQL_SCRIPT
CREATE DATABASE glpi;
CREATE USER 'glpi'@'%' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'%';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

# Install necessary PHP packages
apt -y install php php-{curl,zip,bz2,gd,imagick,intl,apcu,memcache,imap,mysql,cas,ldap,tidy,pear,xmlrpc,pspell,mbstring,json,iconv,xml,gd,xsl}
apt-get -y install php-cli php-cas php-imap php-ldap php-xmlrpc php-soap php-snmp php-apcu

# Install Apache web server and PHP module
apt -y install apache2 libapache2-mod-php

# Configure the httpOnly flag in the php.ini file
sed -i 's/;session.cookie_httponly =/session.cookie_httponly = on/' /etc/php/*/apache2/php.ini

# Download the latest version of GLPI and extract it
GLPI_VERSION=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/glpi-project/glpi/releases/download/$GLPI_VERSION/glpi-$GLPI_VERSION.tgz
tar xvf glpi-$GLPI_VERSION.tgz

# Move the GLPI directory to the Apache root directory
mv glpi /var/www/html/

# Set correct permissions for the GLPI directory
chown -R www-data:www-data /var/www/html/glpi

# Open the browser to the GLPI installation page
xdg-open http://localhost/glpi

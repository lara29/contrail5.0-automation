#!/bin/bash

service mysql restart
sudo mysql -u root -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -u root -e "GRANT ALL ON wordpress.* TO 'wpuser' IDENTIFIED BY 'password';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
sudo mysql -u root -e "EXIT;"

touch /root/completed

#Delete me
rm $0

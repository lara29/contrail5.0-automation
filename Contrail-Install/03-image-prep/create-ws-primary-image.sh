#!/bin/bash

# Copy the original ubuntu image to primary image
cp images/ubuntu-image.img images/ubuntu-webserver-primary.img

# Customize the image
virt-customize -a images/ubuntu-webserver-primary.img \
--root-password password:juniper123 \
--hostname ws-primary \
--run-command 'echo "ubuntu ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/ubuntu' \
--chmod 0440:/etc/sudoers.d/ubuntu \
--copy-in firstboots/primaryfb.sh:/root/ \
--install mysql-server,mysql-client,sshpass,lsyncd,nginx,php-fpm,php-mysql \
--install php-curl,php-gd,php-mbstring,php-mcrypt,php-xml,php-xmlrpc \
--run-command 'sed -i "s/PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config' \
--run-command 'sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config' \
--copy-in configs/default:/etc/nginx/sites-available/ \
--run-command 'systemctl reload nginx' \
--run-command 'wget http://wordpress.org/latest.tar.gz' \
--run-command 'tar -xvf latest.tar.gz' \
--run-command 'mkdir wordpress/wp-content/upgrade' \
--run-command 'sudo cp -a wordpress/. /var/www/html' \
--run-command 'sudo chown -R www-data:www-data /var/www/html' \
--run-command 'sudo find /var/www/html -type d -exec chmod g+s {} \;' \
--run-command 'sudo chmod g+w /var/www/html/wp-content' \
--run-command 'sudo chmod -R g+w /var/www/html/wp-content/themes' \
--run-command 'sudo chmod -R g+w /var/www/html/wp-content/plugins' \
--run-command 'curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar' \
--run-command 'chmod +x wp-cli.phar' \
--run-command 'sudo mv wp-cli.phar /usr/local/bin/wp' \
--run-command 'mkdir -p /etc/lsyncd' \
--copy-in configs/lsyncd.conf.lua:/etc/lsyncd/ \
--copy-in configs/phptest.php:/var/www/html/

sudo service mysql restart
sudo mysql -u root -e "CREATE DATABASE wordpress;"
sudo mysql -u root -e "GRANT ALL ON wordpress.* TO 'wpuser' IDENTIFIED BY 'password';"
sudo mysql -u root -e "FLUSH PRIVILEGES;”

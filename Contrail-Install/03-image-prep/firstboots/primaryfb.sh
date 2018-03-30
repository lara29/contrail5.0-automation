#!bin/bash
db_ip=$(sed -n "1p" "/root/ips")
ws_ip=$(sed -n "2p" "/root/ips")

if [[-e /root/started ]]; then
  echo "Firstboot has already started"
  exit
fi

touch /root/started
echo $IFACE >> /root/started

if [[ $IFACE == lo ]]; then
   echo "loopback is up"
   exit
fi

mkdir -p /root/.ssh

ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

sudo sshpass -p "juniper123" ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$ws_ip
echo "ssh pass completed"
rsync -r /var/www/* root@$ws_ip:/var/www/.
echo "rsync completed"
sudo ssh root@$ws_ip 'sudo service apache2 restart'
echo "remotely executed apache restart"
sed -i "/host/c\host = '$ws_ip'," /etc/lsyncd/lsyncd.conf.lua
echo "set host in lsyncd config file"
service lsyncd start
echo "started the lsyncd process"
service lsyncd restart

#Get my ip address
MY_IFACE=`route | grep '^default' | grep -o '[^ ]*$'`
MY_IP=`/sbin/ifconfig $MY_FACE $1 | grep "inet" | awk -F' ' '{print $2}'| awk -F ':' '{print $2}'|awk "NR==1"`
echo "my ip:"
echo $MY_IP
BASE_URL="http://$MY_IP"

#Set the hostname entry in /etc/hosts
echo "$MY_IP jnpr-example.com ws-primary" >> /etc/hosts
echo "127.0.0.1 ws-primary" >> /etc/hosts 


#Databse info
DB_USER="wpuser"
DB_PASS="password"
DB_NAME="wordpress"
DB_HOST=$db_ip
SITE_PATH=/var/www/html/
 

# Install wordpress
sudo -u www-data -s -- <<EOF   
wp core config --path="/var/www/html/" --path=$SITE_PATH --dbhost=$DB_HOST --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --extra-php <<PHP
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', true);
define('WP_MEMORY_LIMIT', '256M');
PHP
wp core install --path=$SITE_PATH --url=$BASE_URL --title="Contrail Webserver Demo" --admin_user="adminuser" --admin_password="password" --admin_email=lrajan@juniper.com
echo  
EOF

#Delete me
rm $0

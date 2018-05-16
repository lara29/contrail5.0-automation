#!/bin/bash
# OPENSTACK 10 WITH CONTRAIL 4.1 INSTALLATION USING SERVER-MANAGER
# Comannd example ./Contrail-Install.sh
# Authors: Sudhishna Sendhilvelan <ssendhil@juniper.net>, Lakshmi Rajan <lrajan@juniper.net>
# Date written 2018 March 9

HOME_DIR=/root/
DATA_PATH=$HOME_DIR/Contrail_Automation/contrail-host-data.txt
echo "" > $DATA_PATH

echo ""
echo " **************************************************"
echo "      CONTRAIL HA-WEBSERVER DEPLOYMENT PROCESS"
echo "         BMS - SINGLE INTERFACE ALL-IN-ONE"
echo " **************************************************"
echo ""
read -p "Enter Contrail Host IP Address (x.x.x.x) : " ip
read -s -p "Enter Contrail Host Password : " password
echo ""
read -p "Enter Management Interface Name : " miface
read -p "Enter File Server Ip : " file_server

contrail_version=5.0.0-0.40

# Write the ip addresses into the inventory file used by Ansible
IFS='/' read -r -a vm_ip <<< "$ip"
IFS='/' read -r -a file_ip <<< "$file_server"

echo "[local]
localhost ansible_connection=local
[contrail-ubuntu-vm]
${vm_ip[0]}
[contrail-file-server]
${file_ip[0]}
" > /root/contrail5.0-automation/Contrail-Install/all.inv

#Fetch necessary info from the target host
echo ""
echo "Fetching info from Contrail host..."
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/init.yml
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/contrail-host-facts-centos.yaml --extra-vars "iface=$miface"

hostname=`grep "hostname" $DATA_PATH | awk -F' ' '{print $2}'`
ip=`grep "ip" $DATA_PATH | awk -F' ' '{print $2}'`
mac=`grep "mac" $DATA_PATH | awk -F' ' '{print $2}'`
gw=`grep "gw" $DATA_PATH | awk -F' ' '{print $2}'`

echo ""
echo ""
echo " ********************************************"
echo "           TARGET MACHINE DETAILS"
echo " ********************************************"
echo ""
echo " * HOSTNAME          : $hostname"
echo ""
echo " * MGMT IFACE        : $miface"
echo ""
echo " * IP ADDRESS        : $ip"
echo ""
echo " * GATEWAY           : $gw"
echo ""
echo " * MAC ADDRESS       : $mac"
echo ""
echo ""
echo " ********************************************"
read -p ' Confirm above details (Y?N) ? ' choice
while true; do
  case $choice in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y or n";;
    esac
done

while true; do
  echo ""
  echo ""
  echo " ********************************************"
  echo "           CONTRAIL PACKAGE DETAILS"
  echo " ********************************************" 
  echo ""
  echo " * VERSION          : $contrail_version"
  read -p ' Confirm above details (Y?N) ? ' choice
  case $choice in
        [Yy]* ) break;;
        [Nn]* )
          echo ""
          echo ""
          echo "********************************************************"
          read -p " Enter Hostname ($hostname): " tempversion
          contrail_version=${tempversion:-$contrail_version}
          echo "********************************************************"
          echo ""
          echo ""
          break;;
        * ) echo "Please answer y or n";;
   esac
 done


while true; do
echo ""
echo " ********************************************"
echo ""
read -p ' PROCEED WITH THE CONTRAIL SETUP?? (Y/n) ' choice
  case $choice in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer y or n";;
    esac
done

echo ""

echo "contrail_package:
  -
    contrail_version: '$contrail_version'
    file_server: '$file_server'
host_vm:
  -
    hostname: '$hostname'
    password: '$password'
    mac_address: '$mac'
    ip_address: '$ip'
    default_gateway: '$gw'
    management_interface: '$miface'
" > /root/contrail5.0-automation/Contrail-Install/vars/contrail.info

echo ""
echo ""
echo "##############################################################"
echo "                     CONTRAIL SETUP BEGINS"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/10-centos-prep.yml
sleep 5
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/11-contrail-centos-deploy.yml
sleep 5

echo "################# Contrail Deploy - Complete #################"
sleep 5

ansible-playbook -i Contrail-Install/all.inv Contrail-Install/12-post-deploy.yml 

echo ""
echo ""
echo "##############################################################"
echo "                        Network Deploy"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/02-deploy-networks.yml
echo "################## Network Deploy - Complete #################"
sleep 2

echo ""
echo ""
echo "##############################################################"
echo "                      Image Preparation"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/03-image-prep/image-prep.yml
echo "################# Image Preparation - Complete ################"
sleep 2

echo ""
echo ""
echo "##############################################################"
echo "                        Image Upload"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/04-image-upload.yml
echo "################## Image Upload - Complete ###################"
sleep 2

echo ""
echo ""
echo "##############################################################"
echo "                            Flavors"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/05-create-flavors.yml
printf  "Flavors were created.\r"
echo "####################### Flavors - Complete ###################"
sleep 2

echo ""
echo ""
echo "##############################################################"
echo "                        Server Creation"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/06-create-servers.yml
echo "################## Server Creation - Complete #################"
sleep 2

printf "\n\nCONTRAIL SETUP COMPLETE.\n"
echo ""
echo ""
echo "################### CONTRAIL SETUP COMPLETE::: Please find the details below ###################"
echo ""
echo "                   ################## Openstack Dashboard #################"
echo "                   Url: http://<host ip>:80"
echo "                   Username : admin"
echo "                   Password: contrail123"
echo ""
echo "                   ####################### Contrail UI ####################"
echo "                   Url: https://<host ip>:8143"
echo "                   Username: admin"
echo "                   Password: contrail123"
echo ""
echo "                   ################### GUI host credentials ###############"
echo "                   Username: juniper"
echo "                   Password: juniper123"
echo ""
echo "                   ################ Other nodes credentials ###############"
echo "                   Username: root"
echo "                   Password: juniper123"
echo ""
echo "                   ################### Database details ###################"
echo "                   Name: wordpress"
echo "                   Username: wpuser"
echo "                   Password: password"
echo ""
echo "                   ################# Website credentials ##################"
echo "                   User: adminuser"
echo "                   Password: password"
echo ""
echo "################################################################################################"

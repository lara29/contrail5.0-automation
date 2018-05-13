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
echo " **************************************************"
echo ""
read -p "Enter the provider type (bms): " provider
read -p "Enter Contrail Host IP Address ($ip): " tempip
ip=${tempip:-$ip}
read -s -p "Enter Contrail Host Password ($password): " temppassword
password=${temppassword:-$password}
echo ""
read -p "Enter Management Interface Name ($miface): " tempiface
miface=${tempiface:-$miface}
read -p "Enter File Server Ip ($file_server): " tfs
file_server=${tfs:-$file_server}

# Write the ip addresses into the inventory file used by Ansible
IFS='/' read -r -a vm_ip <<< "$ip"
IFS='/' read -r -a file_ip <<< "$file_server"

echo "[local]
localhost ansible_connection=local
[contrail-ubuntu-vm]
${vm_ip[0]}
[contrail-file-server]
${file_ip[0]}
" > /root/Contrail_Automation/Contrail-Install/all.inv

#Fetch necessary info from the target host
echo ""
echo "Fetching info from Contrail host..."
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/init.yml
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/contrail-host-facts.yaml --extra-vars "iface=$miface"

hostname=`grep "hostname" $DATA_PATH | awk -F' ' '{print $2}'`
ip=`grep "ip" $DATA_PATH | awk -F' ' '{print $2}'`
mac=`grep "mac" $DATA_PATH | awk -F' ' '{print $2}'`
gw=`grep "gw" $DATA_PATH | awk -F' ' '{print $2}'`
iface=`grep "iface" $DATA_PATH | awk -F' ' '{print $2}'`

# Hardcoding values that may not change with deployment
provider=bms
contrail_version=latest
cloud_orchestrator=openstack
auth_mode=keystone
rabbitmq_node_port=5673
keystone_auth_url_version=v3
enable_haproxy=no
kolla_internal_vip_address=10.10.7.149
keystone_admin_password=contrail123

echo "ubuntu-version $ubuntu_version" >> $DATA_PATH
echo "contrail-version $contrail_version" >> $DATA_PATH
echo "openstack-version $openstack_version" >> $DATA_PATH
echo "openstack-release $openstack_release" >> $DATA_PATH
echo "cluster-id $cluster_id" >> $DATA_PATH

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
echo " * IP ADDRESS/CIDR   : $ip"
echo ""
echo " * PASSWORD          : ************"
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

echo ""
echo " **************************************************"
echo "Setup configuration parameters from instances.yaml
echo " **************************************************"
cat 
  echo "           CONTRAIL SETUP DETAILS"
  echo " ********************************************"
  echo ""
  echo " * CONTRAIL VERSION      : $cluster_id"
  echo ""
  echo " * CONTRAIL VERSION  : $contrail_version"
  echo ""
  echo " * OPENSTACK SKU     : $openstack_version"
  echo ""
  echo " * OPENSTACK RELEASE : $openstack_release"
  echo ""
  echo " * FILE SERVER       : $file_server"
  echo ""
  echo " ********************************************"

  read -p ' Confirm above details (Y?N) ? ' choice
  case $choice in
        [Yy]* ) break;;
        [Nn]* )
          echo ""
          echo ""
          echo "Enter new values, or press enter to accept default values"
          echo "********************************************************"
          echo "TARGET MACHINE DETAILS: "
          read -p " Enter Hostname ($hostname): " temp
          hostname=${temp:-$hostname}
          read -p " Enter Default Gateway ($gw): " temp
          gw=${temp:-$gw}
          read -p " Enter Mac Address ($mac): " temp
          mac=${temp:-$mac}
          read -p " Enter Ubuntu Version ($ubuntu_version): " temp
          ubuntu_version=${temp:-$ubuntu_version}
          echo "SETUP DETAILS: "
          read -p " Enter cluster id ($cluster_id): " temp
          cluster_id=${temp:-$cluster_id}
          read -p " Enter Contrail Version ($contrail_version): " temp
          contrail_version=${temp:-$contrail_version}
          read -p " Enter Openstack SKU ($openstack_version): " temp
          openstack_version=${temp:-$openstack_version}
          read -p " Enter openstack_release ($openstack_release): " temp
          openstack_release=${temp:-$openstack_release}
          clear
          ;;
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
    id: '$cluster_id'
    contrail_version: '$contrail_version'
    package_sku: '$openstack_version'
    openstack_release: '$openstack_release'
    file_server: '$file_server'
host_vm:
  -
    hostname: '$hostname'
    ubuntu_version: '$ubuntu_version'
    password: '$password'
    mac_address: '$mac'
    ip_address: '$ip'
    default_gateway: '$gw'
    management_interface: '$miface'
" > /root/Contrail_Automation/Contrail-Install/vars/contrail.info

echo ""
echo ""
echo "##############################################################"
echo "                     CONTRAIL SETUP BEGINS"
echo "##############################################################"
echo ""
echo ""

ansible-playbook -i Contrail-Install/all.inv Contrail-Install/11-contrail-centos-deploy.yml
cd contrail-ansible-deployer
ansible-playbook -i inventory/ playbooks/configure_instances.yml
ansible-playbook -i inventory/ -e orchestrator=openstack playbooks/install_contrail.yml

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
echo "                   Url: http://<host ip>:8898"
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

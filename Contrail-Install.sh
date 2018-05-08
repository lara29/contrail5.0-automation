#!/bin/bash
# OPENSTACK 10 WITH CONTRAIL 4.1 INSTALLATION USING SERVER-MANAGER
# Comannd example ./Contrail-Install.sh
# Authors: Sudhishna Sendhilvelan <ssendhil@juniper.net>, Lakshmi Rajan <lrajan@juniper.net>
# Date written 2018 March 9

HOME_DIR=/root/
INFO_PATH=$HOME_DIR/Contrail_Automation/setup-info.txt
DATA_PATH=$HOME_DIR/Contrail_Automation/contrail-host-data.txt
BAS_INFO_PATH=$HOME_DIR/Contrail_Automation/Info.txt
cp $HOME_DIR/BuildAutomationSystem/Info.txt $HOME_DIR/Contrail_Automation/
echo "" > $DATA_PATH

temp_ip=`awk 'NR==1' $BAS_INFO_PATH`
temp_fsp=`awk 'NR==2' $BAS_INFO_PATH`
if [[ -z "$temp_ip" ]]; then
   ip=`grep "targetip" $INFO_PATH | awk -F' ' '{print $2}'`
else
   ip=$temp_ip
fi

if [[ -z "$temp_fsp" ]]; then
   file_server=`grep "fileserverip" $INFO_PATH | awk -F' ' '{print $2}'`
else
   file_server=$temp_fsp
fi
echo "" > $DATA_PATH

echo ""
echo " **************************************************"
echo "      CONTRAIL HA-WEBSERVER DEPLOYMENT PROCESS"
echo " **************************************************"
echo ""
miface=`grep "mgmt-iface" $INFO_PATH | awk -F' ' '{print $2}'`

while true; do
  echo ""
  echo "FILE SERVER"
  echo " IP Address: $file_server"
  echo "CONTRAIL HOST"
  echo " IP Address: $ip"
  echo " Management Iface Name: $miface"
  echo "***********************************"
  echo ""
  read -p 'Confirm above details (Y?N) ? ' choice
  case $choice in
        [Yy]* ) break;;
        [Nn]* )
          echo ""
          echo "Enter new values, or press enter"
          echo "to accept default values"
          echo "***********************************"
          read -p "Enter Management Interface Name ($miface): " tempiface
          miface=${tempiface:-$miface}
          read -p "Enter Contrail Host Address ($ip): " tempip
          ip=${tempip:-$ip}
          read -p "Enter File Server Ip ($file_server): " tfs
          file_server=${tfs:-$file_server}
          clear
          ;;
        * ) echo "Please answer y or n";;
    esac
done

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
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/contrail-host-facts.yaml --extra-vars "iface=$miface"

hostname=`grep "hostname" $DATA_PATH | awk -F' ' '{print $2}'`
ip=`grep "ip" $DATA_PATH | awk -F' ' '{print $2}'`
mac=`grep "mac" $DATA_PATH | awk -F' ' '{print $2}'`
gw=`grep "gw" $DATA_PATH | awk -F' ' '{print $2}'`
iface=`grep "iface" $DATA_PATH | awk -F' ' '{print $2}'`

# Hardcoding values that may not change with deployment
cluster_id=dc135
ubuntu_version=xenial
contrail_version=4.1.0.0-8
openstack_version=ocata
openstack_release=4.0.0
echo "ubuntu-version $ubuntu_version" >> $DATA_PATH
echo "contrail-version $contrail_version" >> $DATA_PATH
echo "openstack-version $openstack_version" >> $DATA_PATH
echo "openstack-release $openstack_release" >> $DATA_PATH
echo "cluster-id $cluster_id" >> $DATA_PATH

while true; do
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
  echo " * GATEWAY           : $gw"
  echo ""
  echo " * MAC ADDRESS       : $mac"
  echo ""
  echo " * UBUNTU OS VERSION : $ubuntu_version "
  echo ""
  echo ""
  echo " ********************************************"
  echo "           CONTRAIL SETUP DETAILS"
  echo " ********************************************"
  echo ""
  echo " * CLUSTER ID        : $cluster_id"
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

echo ""
echo ""
echo "##############################################################"
echo "              Initialize the Destination VM"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/init.yml
echo "################## Intialize - Complete ######################"
sleep 2

echo ""
echo ""
echo "##############################################################"
echo "                      Contrail Deploy"
echo "##############################################################"
echo ""
echo ""
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/01-contrail-50-deploy.yml
cd contrail-ansible-deployer
ansible-playbook -i inventory/ playbooks/configure_instances.yml
ansible-playbook -i inventory/ -e orchestrator=openstack playbooks/install_contrail.yml

echo "################# Contrail Deploy - Complete #################"
sleep 5

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
echo "                   Password juniper123"
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



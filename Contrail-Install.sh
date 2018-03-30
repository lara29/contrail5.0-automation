#!/bin/bash
# OPENSTACK 10 WITH CONTRAIL 4.1 INSTALLATION USING SERVER-MANAGER
# Comannd example ./Contrail-Install.sh
# Date written 2018 March 9

echo ""
echo "PROVIDE HOST VM DETAILS:"
echo ""
echo "###################################################"
echo "You can fetch the HOST VM details from the "
echo "destinaton vm using the command 'ifconfig'."
echo "To accept default values in the bracket click enter."
echo "###################################################"
echo ""
read -p 'Enter Hostname (ubuntu): ' hostname
hostname=${hostname:-ubuntu}

read -p 'Enter Ubuntu Version (xenial): ' ubuntu_version
ubuntu_version=${ubuntu_version:-xenial}

read -p 'Enter Password (c0ntrail123): ' password
password=${password:-c0ntrail123}

read -p 'Enter Management Interface (eno3): ' management_interface
management_interface=${management_interface:-eno3}

read -p 'Enter Mac Address (14:18:77:46:05:67): ' mac_address
mac_address=${mac_address:-14:18:77:46:05:67}

read -p 'Enter IP Address (10.10.7.205/20): ' ip_address
ip_address=${ip_address:-10.10.7.205/20}

read -p 'Enter Default Gateway (10.10.10.1): ' default_gateway
default_gateway=${default_gateway:-10.10.10.1}

echo ""
while
    read -p 'Confirm the details (Y/n): ' answer

    if [ "$answer" = "n" ] || [ "$answer" = "N" ] || [ "$answer" = "no" ] || [ "$answer" = "No" ] || [ "$answer" = "NO" ]
    then
        exit 1
    elif [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Yes" ] || [ "$answer" = "YES" ]
    then
        break
    fi
do :;  done

echo "---------------------------------------------------"
echo ""
echo "PROVIDE CONTRAIL PACKAGE DETAILS:"
echo ""
echo "###################################################"
echo "To accept default values in the bracket click enter."
echo "###################################################"
echo ""
read -p 'Enter cluster id (dc135): ' id
id=${id:-dc135}

read -p 'Enter Contrail Version (4.1.0.0-8): ' contrail_version
contrail_version=${contrail_version:-4.1.0.0-8}

read -p 'Enter Package SKU (ocata): ' package_sku
package_sku=${package_sku:-ocata}

read -p 'Enter openstack_release (4.0.0): ' openstack_release
openstack_release=${openstack_release:-4.0.0}

read -p 'Enter FILE SERVER IP (10.10.7.202): ' file_server
file_server=${file_server:-10.10.7.202}

echo ""

while
    read -p 'Confirm the details (Y/n): ' answer

    if [ "$answer" = "n" ] || [ "$answer" = "N" ] || [ "$answer" = "no" ] || [ "$answer" = "No" ] || [ "$answer" = "NO" ]
    then
        exit 1
    elif [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Yes" ] || [ "$answer" = "YES" ]
    then
        break
    fi
do :;  done

echo ""

while
    read -p 'START WITH THE CONTRAIL SETUP?? (Y/n): ' answer

    if [ "$answer" = "n" ] || [ "$answer" = "N" ] || [ "$answer" = "no" ] || [ "$answer" = "No" ] || [ "$answer" = "NO" ]
    then
        exit 1
    elif [ "$answer" = "y" ] || [ "$answer" = "Y" ] || [ "$answer" = "yes" ] || [ "$answer" = "Yes" ] || [ "$answer" = "YES" ]
    then
        break
    fi
do :;  done

echo ""

echo "contrail_package:
  -
    id: '$id'
    contrail_version: '$contrail_version'
    package_sku: '$package_sku'
    openstack_release: '$openstack_release'
    file_server: '$file_server'
host_vm:
  -
    hostname: '$hostname'
    ubuntu_version: '$ubuntu_version'
    password: '$password'
    management_interface: '$management_interface'
    mac_address: '$mac_address'
    ip_address: '$ip_address'
    default_gateway: '$default_gateway'
" > /root/Contrail_Automation/Contrail-Install/vars/contrail.info

IFS='/' read -r -a vm_ip <<< "$ip_address"
IFS='/' read -r -a file_ip <<< "$file_server"

echo "[local]
localhost ansible_connection=local

[contrail-ubuntu-vm]
${vm_ip[0]}

[contrail-file-server]
${file_ip[0]}
" > /root/Contrail_Automation/Contrail-Install/all.inv

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
ansible-playbook -i Contrail-Install/all.inv Contrail-Install/01-contrail-server-manager.yml
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



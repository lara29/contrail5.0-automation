#Run the tasks required to set the stage for automation
echo "**********************************"
echo "Contrail host details:"
echo "**********************************"
read -p 'Enter username: ' hostusername
read -p 'Enter username: ' hostpassword
echo "**********************************"
echo ""
echo ""
echo "Establishing connection with all hosts in the inventory"
python3 establish_connection.py

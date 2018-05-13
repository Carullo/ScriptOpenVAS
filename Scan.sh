ip_server=$(cat ip)

sshpass -p OpenVA94 scp -o "StrictHostKeyChecking no" $ip_server:/home/project/Scrivania/target.txt ./

target=$(cat target.txt)

wget https://raw.githubusercontent.com/Carullo/ScriptOpenVAS/master/openvas-automate.sh

chmod +x openvas-automate.sh

./openvas-automate.sh $target

sshpass -p OpenVA94 scp ./*$target* $ip_server:/home/project/Scrivania/

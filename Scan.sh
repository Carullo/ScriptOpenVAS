ip_server=$(cat ip)

scp root@$ip_server:/home/project/Scrivania/target.txt ./

target=$(cat target.txt)

wget https://raw.githubusercontent.com/Carullo/ScriptOpenVAS/master/openvas-automate.sh

chmod +x openvas-automate.sh

./openvas-automate.sh $target

scp ./$target.* root@$ip_server:/home/project/Scrivania/

ready=0

RET=$(ps aux | grep -i "openvassd" | grep -i "waiting")
if [ $? -ne 0 ]; then
	echo "[+]OpenVAS is not running. Initialization in progress..."
	./Init.sh
else
	ready=1
	echo "[+]OpenVAS is ready!"		
fi

./openvas-automate.sh $@

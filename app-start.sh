#!/bin/bash

DIR_SCRIPT_SHELL=/root/CloudDrive/Applications/scripts/shell
DIR_INSTALL_FRP=/root/CloudDrive/Applications/frp

#ntpdate 2.asia.pool.ntp.org
#sleep 1

bash ${DIR_INSTALL_FRP}/frp-mon.sh
sleep 1

#bash ${DIR_SCRIPT_SHELL}/das-mount nfs
#sleep 1

#bash ${DIR_SCRIPT_SHELL}/fm-mon.sh
#sleep 1

python /opt/gateone/gateone.py &

su - rslsync nohup syncthing &
exit


#!/bin/sh
#

# Attenzione questo script viene richiamato dallo script di backup di Tivoli
# /usr/bin/backup_tsm_pre.sh (e post.sh) per avviare sybase
# Non va bene per l'uso da linea comando
# Da linea comando va usato il nohup prima e il & dopo

/sybase/ASE-12_5/install/startserver -f /sybase/ASE-12_5/install/RUN_MX1_DEV_2
sleep 10
/sybase/ASE-12_5/install/startserver -f /sybase/ASE-12_5/install/RUN_MX1_DEV_2_back
sleep 10
#/sybase/ASE-12_5/install/startserver -f /sybase/ASE-12_5/install/RUN_MX1_DEV_2_mon
echo
exit 0


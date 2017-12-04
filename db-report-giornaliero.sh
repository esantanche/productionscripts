#!/bin/sh -x
#

# ATTENZIONE QUESTO SCRIPT VA PERSONALIZZATO SU OGNI MACCHINA

#. /home/sybase/.profile

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

DATA=$(/usr/bin/date +%Y%m%d)

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# DA migliorare: e' bene estrarre i dati anche della sola occupazione

sh $UTILITY_DIR/db-singolo-space-report.sh   CAP_REPORT
sh $UTILITY_DIR/db-singolo-space-report.sh   CAP_SVIL
sh $UTILITY_DIR/db-singolo-space-report.sh   CAP_TEST
sh $UTILITY_DIR/db-singolo-space-report.sh   tempdb

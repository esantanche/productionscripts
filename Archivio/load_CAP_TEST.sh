#!/bin/sh 

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# bcp CAP_REPORT..sysusers out /sybase/utility/data/sysusers_capreport.bcp -c -P capdevpwd -S MX1_DEV_2 -U sa 

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

gunzip /sybased1/dump/CAP_PROD_TO_LOAD.dmp.gz

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF 
load database CAP_TEST from "/sybased1/dump/CAP_PROD_TO_LOAD.dmp"
go
online database CAP_TEST
go
exit
EOF

gzip /sybased1/dump/CAP_PROD_TO_LOAD.dmp

echo Allineamento del db CAP_TEST concluso


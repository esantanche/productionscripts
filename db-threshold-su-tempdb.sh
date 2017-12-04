#!/bin/sh 
#

#. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# 14.9.2005 il thr del 75% è diventato urgente

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-threshold-su-tempdb <<EOF
use tempdb
go
sp_addthreshold tempdb,"default",250000,sp_thresholdaction
go
if @@error != 0 select 'errore-db-threshold-su-tempdb'
go
sp_addthreshold tempdb,"default",200000,sp_thresholdaction
go
if @@error != 0 select 'errore-db-threshold-su-tempdb'
go
sp_addthreshold tempdb,"default",125000,sp_thresholdaction
go
if @@error != 0 select 'errore-db-threshold-su-tempdb'
go
sp_addthreshold tempdb,"default",80000,sp_thr_urgente
go
if @@error != 0 select 'errore-db-threshold-su-tempdb'
go
select "COLLEGATOOK"
go
quit
EOF

COLLOK=`grep "COLLEGATOOK" /tmp/db-threshold-su-tempdb | wc -l`
if [ $COLLOK -eq 0 ] ; then
   echo $DATA Non mi sono collegato >> $UTILITY_DIR/out/errori_db-threshold-su-tempdb
   exit 1
fi 

ERRINQUERY=`grep "errore-db-threshold-su-tempdb" /tmp/db-threshold-su-tempdb | wc -l`
if [ $ERRINQUERY -gt 0 ] ; then
   echo $DATA Errore in db-threshold-su-tempdb.sh >> $UTILITY_DIR/out/errori_db-threshold-su-tempdb
   exit 1
fi


rm /tmp/db-threshold-su-tempdb

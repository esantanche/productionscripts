#!/bin/sh 
#

. /home/sybase/.profile

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi


DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF
disk init name = "CAP_PROD@NEW#D01", physname = "/syb_db_CAP_PROD/CAP_PROD#D01.sybdev", size = "24000M"
go
disk init name = "CAP_PROD@NEW#L01", physname = "/syb_db_CAP_PROD/CAP_PROD#L01.sybdev", size = "8000M"
go
create database CAP_PROD@NEW on CAP_PROD@NEW#D01 = "24000M" log on CAP_PROD@NEW#L01 = "8000M"
go
sp_dboption CAP_PROD@NEW, "select into/bulkcopy/pllsort", true
go
sp_dboption CAP_PROD@NEW, "trunc log on chkpt", true
go
use CAP_PROD@NEW
go
checkpoint
go
use master
go
dbcc checkdb(CAP_PROD@NEW)
go
dbcc checkcatalog(CAP_PROD@NEW)
go
dbcc checkalloc(CAP_PROD@NEW)
go
quit
EOF

FINE_ORE=$(/usr/bin/date +%H)       
FINE_MIN=$(/usr/bin/date +%M)   

echo $DATA $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN | nawk '
                                    { inizio_ore=$2;
                                      inizio_min=$3;
                                      fine_ore=$4;
                                      fine_min=$5;
                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
                                      if (diff < 0) { diff += 1440; };
                                      print "Tempo impiegato";
                                      print "====================================";
                                      printf "Inizio ore %02d:%02d\n",inizio_ore,inizio_min;
                                      printf "Fine ore   %02d:%02d\n",fine_ore,fine_min;
                                      printf "Durata ore %02d:%02d\n",int(diff/60),diff % 60;
                                    }'  

exit 0;


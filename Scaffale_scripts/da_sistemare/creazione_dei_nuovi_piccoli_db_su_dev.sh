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

#innanzitutto vedere i prerequisiti
#  controllare che non ci siano gia' device con lo stesso nome
#per ogni db creaz device e db e dboptions
#lasciamo perdere i dbcc
#controllare che non ci siano gia' i device

# ACT_CAP_SVIL         FATTO
# CAP_REPORT           --- non e' un piccolo db
# CAP_SVIL             --- non e' un piccolo db
# CAP_TEST             --- non e' un piccolo db
# MLC_CAP_REPORT       FATTO
# MLC_CAP_SVIL         FATTO
# MLC_CAP_TEST         FATTO
# SIF_TEST             FATTO
# dbccdb                CASO A PARTE
# kymx_dbadb           FATTO
# master                  raw dev
# model                   raw dev
# sybsystemdb             raw dev
# sybsystemprocs          raw dev
# tempdb               OK

DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF
disk init name = "ACT_CAP_SVIL#M01", physname = "/syb_db_piccoli_db/ACT_CAP_SVIL#M01.sybdev", size = "250M"
go 
create database ACT_CAP_SVIL@NEW on ACT_CAP_SVIL#M01 = "250M"
go
disk init name = "MLC_CAP_REPORT#D01", physname = "/syb_db_piccoli_db/MLC_CAP_REPORT#D01.sybdev", size = "500M"
go
disk init name = "MLC_CAP_REPORT#L01", physname = "/syb_db_piccoli_db/MLC_CAP_REPORT#L01.sybdev", size = "500M"
go
create database MLC_CAP_REPORT@NEW on MLC_CAP_REPORT#D01 = "500M" log on MLC_CAP_REPORT#L01 = "500M"
go
disk init name = "MLC_CAP_TEST#D01", physname = "/syb_db_piccoli_db/MLC_CAP_TEST#D01.sybdev", size = "1000M"
go
disk init name = "MLC_CAP_TEST#L01", physname = "/syb_db_piccoli_db/MLC_CAP_TEST#L01.sybdev", size = "500M"
go
create database MLC_CAP_TEST@NEW on MLC_CAP_TEST#D01 = "1000M" log on MLC_CAP_TEST#L01 = "500M"
go
disk init name = "SIF_TEST@NEW#D01", physname = "/syb_db_piccoli_db/SIF_TEST#D01.sybdev", size = "1500M"
go
disk init name = "SIF_TEST#L01", physname = "/syb_db_piccoli_db/SIF_TEST#L01.sybdev", size = "1000M"
go
create database SIF_TEST@NEW on SIF_TEST@NEW#D01 = "1500M" log on SIF_TEST#L01 = "1000M"
go
sp_dboption ACT_CAP_SVIL@NEW, "select into/bulkcopy/pllsort", true
go
sp_dboption ACT_CAP_SVIL@NEW, "trunc log on chkpt", true
go
sp_dboption MLC_CAP_REPORT@NEW, "select into/bulkcopy/pllsort", true
go
sp_dboption MLC_CAP_REPORT@NEW, "trunc log on chkpt", true
go
sp_dboption MLC_CAP_TEST@NEW, "select into/bulkcopy/pllsort", true
go
sp_dboption MLC_CAP_TEST@NEW, "trunc log on chkpt", true
go
sp_dboption SIF_TEST@NEW, "select into/bulkcopy/pllsort", true
go
sp_dboption SIF_TEST@NEW, "trunc log on chkpt", true
go
use ACT_CAP_SVIL@NEW
go
checkpoint
go
use MLC_CAP_REPORT@NEW
go
checkpoint
go
use MLC_CAP_TEST@NEW
go
checkpoint
go
use SIF_TEST@NEW
go
checkpoint
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


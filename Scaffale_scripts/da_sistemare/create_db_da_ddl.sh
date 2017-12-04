#!/bin/sh 
#


# Parametri da passare: nome del db e data aaaammgg
NOMEDDL=$1   # la trovo nella dir UTLITY_DIR

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

#export UTILITY_DIR=/sybase/utility
#export SAUSER=sa
#export SAPWD=capdevpwd
#export NOTSAUSER=test
#export NOTSAPWD=test
#export ASE_NAME=MX1_DEV_2
#export HOME_OF_SYBASE=/home/sybase
#export PATH_ERRORLOG_ASESERVER=/sybase/ASE-12_5/install/MX1_DEV_2.log 
#export PATH_ERRORLOG_BACKUPSERVER=/sybase/ASE-12_5/install/MX1_DEV_2_back.log
#export SOGLIA_FS_DUMP_MB=1000
#export SOGLIA_FS_DB_MB=3000
#export PATH_INSTALLDIR=/sybase/ASE-12_5/install
#export SUNDAYDIR=/sybased2/sunday_dir

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $UTILITY_DIR/$NOMEDDL > $UTILITY_DIR/output-$NOMEDDL

exit 0



#!/bin/sh 
#

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

DATA=$(/usr/bin/date +%Y%m%d)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

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

echo $(date)

NUMERODB=0
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------|@'
set nocount on
go
select name from sysdatabases order by name
go
EOF`
do
       sleep 10
       sh $UTILITY_DIR/fixsegmap_singolodb.sh $i 
       sleep 10
       #echo $i
       NUMERODB=`expr $NUMERODB + 1`
done

#echo $NUMERODB

exit 0;



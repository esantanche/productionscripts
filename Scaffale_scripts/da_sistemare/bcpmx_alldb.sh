#!/bin/sh 
#

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

#DATA=$(/usr/bin/date +%Y%m%d)

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

# Pulizia directory sunday_dir
sh $UTILITY_DIR/clean_sunday_dir.sh 

# Questa impostazione va fatta per evitare che il bcp dia problemi di
# memoria
ulimit -d unlimited

rm -f $UTILITY_DIR/out/esito_bcp

DB_NOBCP=`grep DB_NO_BCP $UTILITY_DIR/bcpmx_parametri | cut -f 2 -d =`

echo Db di cui non fare bcp:
echo $DB_NOBCP

# Va modificato prendendo per ogni db il suo clone
# aggiungere quindi una riga
# $iclone=$i@BCP
# Vanno evitati gli stessi cloni nell'elenco dei db
# ovvero  egrep -v 'name|----------|@'
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases where name not in ($DB_NOBCP) order by name
go
EOF`
do
       sleep 10
       echo $(/usr/bin/date +%Y%m%d-%H:%M:%S) Inizio bcp database $i
       sh $UTILITY_DIR/bcpmx_singolodb.sh $i 
       ERROREBCP=$?
       if [ $ERROREBCP -gt 0 ] ; then
          echo ERRORE NEL BCP DI $i
          exit 1
       fi
       sleep 20
done

exit 0

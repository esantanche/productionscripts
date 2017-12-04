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

#/sybase/sybcent32/ddlgen -U$SAUSER -P$SAPWD -Smx1-dev-2:4100 -O$SUNDAYDIR/ddlmx_$ASE_NAME -E$SUNDAYDIR/ddlmx_$ASE_NAME.err

DB_NODDL=`grep DB_NO_DDL $UTILITY_DIR/ddlmx_parametri | cut -f 2 -d =`

echo Db di cui non fare ddl:
echo $DB_NODDL

# Va modificato per fare il ddlgen del db clone
# il $i va trasformato in un $iclone=$i@BCP
# Vanno evtati i cloni stessi: egrep -v 'name|----------|@'
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases where name not in ($DB_NODDL) order by name
go
EOF`
do
       sleep 10
       echo $(/usr/bin/date +%Y%m%d-%H:%M:%S) Inizio ddl database $i
       /sybase/sybcent32/ddlgen -U$SAUSER -P$SAPWD -S`hostname`:4100 -D$i -O$SUNDAYDIR/ddlmx_$i.sql -E$SUNDAYDIR/ddlmx_$i.err 1>/dev/null
       ERROREDDL=$?
       if [ $ERROREDDL -gt 0 ] ; then
          echo ERRORE NEL DDL DI $i
          exit 1
       fi
       if [ -s $SUNDAYDIR/ddlmx_$i.err ] ; then
          echo ERRORE IN FILE ERRORI DI DDL $i
          exit 1
       else
          rm -f $SUNDAYDIR/ddlmx_$i.err
       fi
       sleep 20
done

exit 0

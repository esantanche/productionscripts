#!/bin/sh 
#

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

#export SYBASE_VG_NAME=sybasevg

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

#date > /tmp/date-dump.log

DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    

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

#   rm qualcosa?
rm -f $UTILITY_DIR/out/grant_log

ERRORE_DA_SEGNALARE=0
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | grep DBNAME | awk '{ print $2; }'
set nocount on
go
select 'DBNAME',name from sysdatabases order by name
go
EOF`
do
       #echo "============="$i
       for og in `cat $UTILITY_DIR/grant-select-lista-owner-grantee`
       do
          o=`echo $og | cut -d "," -f 1`
          g=`echo $og | cut -d "," -f 2` 
          #echo $og   $o $g
          #echo "grant-select-singolo-db.sh "$i" "$o" "$g
          sh $UTILITY_DIR/grant-select-singolo-db.sh $i $o $g
          CODICE_RITORNO=$?
          #echo Codice ritorno $CODICE_RITORNO
          #echo Codice ritorno $CODICE_RITORNO $i $o $g
          if [ $CODICE_RITORNO -gt 0 -a \( $CODICE_RITORNO -lt 3 -o $CODICE_RITORNO -gt 4 \) ] ; then
             # Problema da segnalare
             ERRORE_DA_SEGNALARE=1
          fi
       done
done

if [ $ERRORE_DA_SEGNALARE -eq 1 ] ; then
   echo "Subject: [GRANT] ERRORI IN OPERAZIONE DI GRANT SELECT "`hostname`  >  /tmp/grant$$.mail
else
   echo "Subject: [GRANT] Ok grant select "`hostname` >  /tmp/grant$$.mail
fi

echo "To: dba@kyneste.com"  >> /tmp/grant$$.mail
echo " " >> /tmp/grant$$.mail
echo "(Made by $UTILITY_DIR/grant-select-all-db.sh)"  >> /tmp/grant$$.mail
echo " " >> /tmp/grant$$.mail

if [ $ERRORE_DA_SEGNALARE -eq 1 ] ; then
   echo "Errori nello svolgimento delle grant" >> /tmp/grant$$.mail
else
   echo "Lista db e numero di tabelle di cui e' stato fatto il grant" >> /tmp/grant$$.mail
   echo "=========================================================" >> /tmp/grant$$.mail
   cat $UTILITY_DIR/out/grant_log >> /tmp/grant$$.mail
fi

if [ $ERRORE_DA_SEGNALARE -eq 1 ] ; then
   cp /tmp/grant$$.mail /nagios_reps/errore_nel_dare_le_grant_$(date +%Y%m%d%H%M)
fi

#/usr/sbin/sendmail -f grant@kyneste.com dba@kyneste.com < /tmp/grant$$.mail

rm -f /tmp/grant$$.mail

exit 0


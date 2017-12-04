#!/bin/sh -x
#

SOGLIA_TABELLE=100000
SOGLIA_PERCENT=20

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# DA migliorare: e' bene estrarre i dati anche della sola occupazione
# Il parametro su linea comando e' il nome del db
NOMEDB=$1
#$UTILITY_DIR/out/lista_dei_db 

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-tempdb-alert1 <<EOF
set nocount on
go
use tempdb
go
sp_spaceused
go
select "COLLEGATOOK"
go
quit
EOF

COLLOK=`grep "COLLEGATOOK" /tmp/db-tempdb-alert1 | wc -l`
if [ $COLLOK -eq 0 ] ; then
   rm /tmp/db-tempdb-alert1
   exit 0
fi 


DIMENSIONE_TOTALE_MB=`tail -n +3 /tmp/db-tempdb-alert1 | head -1 | awk '{ printf "%5.0f\n",$2; }'`

SPAZIO_OCCUPATO=`tail -n +6 /tmp/db-tempdb-alert1 | head -1 | awk '{ printf "%5.0f\n",$1/1000; }'`

PERCENT=`echo $DIMENSIONE_TOTALE_MB $SPAZIO_OCCUPATO | awk '{ printf "%5.0f\n",100*$2/$1; }'`

echo $DATA $DIMENSIONE_TOTALE_MB $SPAZIO_OCCUPATO $PERCENT | awk '{ printf "%-15s %5.0f %5.0f %4.0f\n",$1,$2,$3,$4; }' >>$UTILITY_DIR/out/db-tempdb-alert-spazio

rm /tmp/db-tempdb-alert1

if [ $PERCENT -gt $SOGLIA_PERCENT ] ; then 
   echo ===================================================================== >> $UTILITY_DIR/out/db-tempdb-alert-hitparade
   echo $DATA $DIMENSIONE_TOTALE_MB $SPAZIO_OCCUPATO $PERCENT >> $UTILITY_DIR/out/db-tempdb-alert-hitparade
   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 > /tmp/db-tempdb-alert2 <<EOF
set nocount on
go
use tempdb
go
select id,object_name(id) as name,4096*sum(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg)) as space from sysindexes group by id  having 4096*sum(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg)) > $SOGLIA_TABELLE order by space
go
quit
EOF
   cat /tmp/db-tempdb-alert2 >> $UTILITY_DIR/out/db-tempdb-alert-hitparade
   # Devo mandare un messaggio

   echo "Subject: [TEMPDBALERT] tempdb occupato al " $PERCENT "%" >  /tmp/db-tempdb-alert.mail
   echo "To: csc@kyneste.com,mcarbone@kyneste.com,si.finanzaintegrata@bancaroma.it"  >> /tmp/db-tempdb-alert.mail
   echo "Il database tempdb su mx2-prod-pridb e' pieno al " $PERCENT "%." >> /tmp/db-tempdb-alert.mail 
   echo "Segue l'elenco delle tabelle che occupano piu' di "$SOGLIA_TABELLE" bytes." >> /tmp/db-tempdb-alert.mail
   echo "Lo spazio e' in bytes." >> /tmp/db-tempdb-alert.mail
   echo "===============================================================" >> /tmp/db-tempdb-alert.mail 
   cat  /tmp/db-tempdb-alert2  >> /tmp/db-tempdb-alert.mail
   echo "===============================================================" >> /tmp/db-tempdb-alert.mail
   # cat $UTILITY_DIR/out/report-spazio-libero-sybasevg >> /tmp/db-tempdb-alert.mail

   /usr/sbin/sendmail -f tempdbalert@kyneste.com si.finanzaintegrata@bancaroma.it < /tmp/db-tempdb-alert.mail
   /usr/sbin/sendmail -f tempdbalert@kyneste.com dba@kyneste.com < /tmp/db-tempdb-alert.mail 
   #/usr/sbin/sendmail -f tempdbalert@kyneste.com esantanche@tim.it < /tmp/db-tempdb-alert.mail 
   /usr/sbin/sendmail -f tempdbalert@kyneste.com csc@kyneste.com <  /tmp/db-tempdb-alert.mail
   /usr/sbin/sendmail -f tempdbalert@kyneste.com mcarbone@kyneste.com < /tmp/db-tempdb-alert.mail

   cp /tmp/db-tempdb-alert.mail /nagios_reps/Tempdb_pieno

   rm -f /tmp/db-tempdb-alert.mail 

fi    

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-tempdb-alert3 <<EOF
begin
declare @id_del_db smallint
declare @Spazio_dati_libero_Mb int
declare @Spazio_log_libero_Mb int
set nocount on
select @id_del_db = dbid from sysdatabases where name like 'tempdb'
select @Spazio_dati_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)*4096/1048576))  from sysusages where dbid=@id_del_db and segmap & 3 = 3
select @Spazio_log_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)*4096/1048576))  from sysusages where dbid=@id_del_db and segmap & 4 = 4
select 'DATI_LIBERO_MB',@Spazio_dati_libero_Mb
select 'LOG_LIBERO_MB',@Spazio_log_libero_Mb
end
go
quit
EOF

DATI_LIBERO_MB=`grep DATI_LIBERO_MB /tmp/db-tempdb-alert3 | awk '{ print $2; }'`
LOG_LIBERO_MB=`grep LOG_LIBERO_MB /tmp/db-tempdb-alert3 | awk '{ print $2; }'`

PERCENT_DATI=`echo $DIMENSIONE_TOTALE_MB $DATI_LIBERO_MB | awk '{ printf "%5.0f\n",(100-100*$2/$1); }'`
PERCENT_LOG=`echo $DIMENSIONE_TOTALE_MB $LOG_LIBERO_MB | awk '{ printf "%5.0f\n",(100-100*$2/$1); }'`

PERCENT=$PERCENT_DATI
if [ $PERCENT_LOG -gt $PERCENT ] ; then
   PERCENT=$PERCENT_LOG
fi 

echo $DATA $DIMENSIONE_TOTALE_MB $DATI_LIBERO_MB $LOG_LIBERO_MB | awk '{ printf "%-15s %5.0f %5.0f %5.0f\n",$1,$2,$3,$4; }' >>$UTILITY_DIR/out/db-tempdb-alert-spazio-sysusages

#SOGLIA_PERCENT=0 #?????

if [ $PERCENT -gt $SOGLIA_PERCENT ] ; then

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 > /tmp/db-tempdb-alert4 <<EOF
set nocount on
go
use tempdb
go
select id,object_name(id) as name,4096*sum(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg)) as space from sysindexes group by id  having 4096*sum(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg)) > $SOGLIA_TABELLE order by space
go
quit
EOF

   echo ===================================================================== >> $UTILITY_DIR/out/db-tempdb-alert-hitparade
   echo $DATA $DIMENSIONE_TOTALE_MB  $DATI_LIBERO_MB $LOG_LIBERO_MB >> $UTILITY_DIR/out/db-tempdb-alert-hitparade

   cat /tmp/db-tempdb-alert4 >> $UTILITY_DIR/out/db-tempdb-alert-hitparade

   echo "Subject: [TEMPDBALERT] tempdb occupato al "$PERCENT "%" >  /tmp/db-tempdb-alert.mail
   echo "To: csc@kyneste.com,mcarbone@kyneste.com,si.finanzaintegrata@bancaroma.it"  >> /tmp/db-tempdb-alert.mail
   echo "Il database tempdb su mx2-prod-pridb e' pieno al "$PERCENT "%." >> /tmp/db-tempdb-alert.mail
   echo "Precisamente il segmento dati risulta occupare il "$PERCENT_DATI "%" >> /tmp/db-tempdb-alert.mail
   echo "e il segmento log risulta occupare il "$PERCENT_LOG "%." >> /tmp/db-tempdb-alert.mail 

   echo "Segue l'elenco delle tabelle che occupano piu' di "$SOGLIA_TABELLE" bytes." >> /tmp/db-tempdb-alert.mail
   echo "Lo spazio e' in bytes." >> /tmp/db-tempdb-alert.mail
   echo "===============================================================" >> /tmp/db-tempdb-alert.mail
   cat  /tmp/db-tempdb-alert4  >> /tmp/db-tempdb-alert.mail
   echo "===============================================================" >> /tmp/db-tempdb-alert.mail

   /usr/sbin/sendmail -f tempdbalert@kyneste.com si.finanzaintegrata@bancaroma.it < /tmp/db-tempdb-alert.mail
   /usr/sbin/sendmail -f tempdbalert@kyneste.com dba@kyneste.com < /tmp/db-tempdb-alert.mail
   #/usr/sbin/sendmail -f tempdbalert@kyneste.com esantanche@tim.it < /tmp/db-tempdb-alert.mail
   /usr/sbin/sendmail -f tempdbalert@kyneste.com csc@kyneste.com <  /tmp/db-tempdb-alert.mail
   /usr/sbin/sendmail -f tempdbalert@kyneste.com mcarbone@kyneste.com < /tmp/db-tempdb-alert.mail

   cp /tmp/db-tempdb-alert.mail /nagios_reps/Tempdb_pieno

   rm -f /tmp/db-tempdb-alert.mail

fi


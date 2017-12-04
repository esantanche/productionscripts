#!/bin/sh -x
#

SOGLIA_PERCENT=0

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


isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-tempdb-alert3 <<EOF
begin
declare @id_del_db smallint
declare @Spazio_libero_Mb int
set nocount on
select @id_del_db = dbid from sysdatabases where name = 'tempdb'
select @Spazio_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)*4096/1048576))  from sysusages where dbid=@id_del_db
select 'DIM_TOTALE_MB',sum(size)*4096/1048576 from sysusages where dbid=@id_del_db
select 'LIBERO_MB',@Spazio_libero_Mb
end
go
quit
EOF

#iuse tempdb
#select 'OCCUPATO_MB',4096*sum(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg))/1048576 as space from sysindexes
#select 'OCCUPATO_LOG',4096*sum(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg))/1048576 as space from sysindexes where name='syslogs
#'


echo =============================================================

cat /tmp/db-tempdb-alert3

DIM_TOTALE_MB=`grep DIM_TOTALE_MB /tmp/db-tempdb-alert3 | awk '{ print $2; }'`
LIBERO_MB=`grep LIBERO_MB /tmp/db-tempdb-alert3 | awk '{ print $2; }'`
OCCUPATO_MB=`grep OCCUPATO_MB /tmp/db-tempdb-alert3 | awk '{ print $2; }'`
OCCUPATO_LOG=`grep OCCUPATO_LOG /tmp/db-tempdb-alert3 | awk '{ print $2; }'`

RISERVATO_MB=`echo $DIM_TOTALE_MB $LIBERO_MB | awk '{ printf "%5.0f\n",$1-$2; }'`
PERCENT=`echo $DIM_TOTALE_MB $RISERVATO_MB | awk '{ printf "%5.0f\n",100*$2/$1; }'`

echo $DATA $DIM_TOTALE_MB $RISERVATO_MB $OCCUPATO_MB $OCCUPATO_LOG $PERCENT | awk '{ printf "%-15s %5.0f %5.0f %5.0f %5.0f %5.0f\n",$1,$2,$3,$4,$5,$6; }' >>$UTILITY_DIR/out/db-tempdb-alert-spazio-sysusages

#SOGLIA_PERCENT=0 #?????

if [ $PERCENT -gt $SOGLIA_PERCENT ] ; then

   echo "Subject: [TEMPDBALERT] tempdb occupato al "$PERCENT "%" >  /tmp/db-tempdb-alert.mail
   echo "To: csc@kyneste.com,mcarbone@kyneste.com,si.finanzaintegrata@bancaroma.it"  >> /tmp/db-tempdb-alert.mail
   echo "Il database tempdb su mx2-prod-pridb e' pieno al "$PERCENT "%." >> /tmp/db-tempdb-alert.mail
   echo "Dimensione complessiva db      "$DIM_TOTALE_MB >> /tmp/db-tempdb-alert.mail
   echo "Spazio occupato complessivo    "$RISERVATO_MB >> /tmp/db-tempdb-alert.mail
   echo "Di cui per dati e log          "$OCCUPATO_MB >> /tmp/db-tempdb-alert.mail
   echo "Di cui per log                 "$OCCUPATO_LOG >> /tmp/db-tempdb-alert.mail
   echo "La differenza tra lo spazio complessivo e quello riservato per dati e log e'" >> /tmp/db-tempdb-alert.mail
   echo "riservata per le aree di sort." >> /tmp/db-tempdb-alert.mail 

   #/usr/sbin/sendmail -f tempdbalert@kyneste.com si.finanzaintegrata@bancaroma.it < /tmp/db-tempdb-alert.mail
   /usr/sbin/sendmail -f tempdbalert@kyneste.com dba@kyneste.com < /tmp/db-tempdb-alert.mail
   #/usr/sbin/sendmail -f tempdbalert@kyneste.com esantanche@tim.it < /tmp/db-tempdb-alert.mail
   #/usr/sbin/sendmail -f tempdbalert@kyneste.com csc@kyneste.com <  /tmp/db-tempdb-alert.mail
   #/usr/sbin/sendmail -f tempdbalert@kyneste.com mcarbone@kyneste.com < /tmp/db-tempdb-alert.mail

   #cp /tmp/db-tempdb-alert.mail /nagios_reps/Tempdb_pieno

   #rm -f /tmp/db-tempdb-alert.mail

fi


exit


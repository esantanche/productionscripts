#!/bin/sh

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

SOGLIA_SPAZIO_LIBERO_DATI_MB=4000
SOGLIA_SPAZIO_LIBERO_LOG_MB=4000

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db"
   exit 0
fi

NOMEDB=$1

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

# In caso di mancato collegamento all'ASE ipotizziamo che sia giu' per riavvio programmato
# e usciamo
if [ a$DBESISTENTE = a ] ; then
   exit 0
fi

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 1;
fi

Messaggio_dati_sotto_soglia () {

   echo Db in situazione critica per mancanza di spazio intervenire urgentemente
   echo Nome db $NOMEDB
   echo Segmento critico DATI
   echo Spazio rimasto $SPAZIO_LIBERO_DATI

}

Messaggio_log_sotto_soglia () {

   echo Db in situazione critica per mancanza di spazio intervenire urgentemente
   echo Nome db $NOMEDB
   echo Segmento critico LOG
   echo Spazio rimasto $SPAZIO_LIBERO_LOG

}

SEGMAP=3

SPAZIO_LIBERO_DATI=`isql -Utest -Ptestpwd -S$ASE_NAME -w400 << EOF | grep "LIBERO_MB" | awk '{ print int($2); }'
begin
declare @id_del_db smallint
declare @Spazio_libero_Mb dec
set nocount on
select @id_del_db = dbid from sysdatabases where name like \"$NOMEDB\"
select @Spazio_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256)) from sysusages where dbid=@id_del_db and segmap & $SEGMAP = $SEGMAP
select \"LIBERO_MB\",@Spazio_libero_Mb
end
go
quit
EOF`

SEGMAP=4

SPAZIO_LIBERO_LOG=`isql -Utest -Ptestpwd -S$ASE_NAME -w400 << EOF | grep "LIBERO_MB" | awk '{ print int($2); }'
begin
declare @id_del_db smallint
declare @Spazio_libero_Mb dec
set nocount on
select @id_del_db = dbid from sysdatabases where name like \"$NOMEDB\"
select @Spazio_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256)) from sysusages where dbid=@id_del_db and segmap & $SEGMAP = $SEGMAP
select \"LIBERO_MB\",@Spazio_libero_Mb
end
go
quit
EOF`

#echo SPAZIO_LIBERO_DATI=$SPAZIO_LIBERO_DATI
#echo SPAZIO_LIBERO_LOG=$SPAZIO_LIBERO_LOG
#SOGLIA_SPAZIO_LIBERO_DATI_MB=3000
#SOGLIA_SPAZIO_LIBERO_LOG_MB=4000

PATH_MSG=/tmp/.oggi/monitor_db_spazi_liberi.msg

if [ $SPAZIO_LIBERO_DATI -lt $SOGLIA_SPAZIO_LIBERO_DATI_MB ] ; then

   Messaggio_dati_sotto_soglia > $PATH_MSG    

   sh $UTILITY_DIR/centro_unificato_messaggi.sh SPAZIO_DB ${NOMEDB}_DATI_${SPAZIO_LIBERO_DATI} 1 0 0 $PATH_MSG

fi

if [ $SPAZIO_LIBERO_LOG -lt $SOGLIA_SPAZIO_LIBERO_LOG_MB ] ; then

   Messaggio_log_sotto_soglia > $PATH_MSG    

   sh $UTILITY_DIR/centro_unificato_messaggi.sh SPAZIO_DB ${NOMEDB}_LOG_${SPAZIO_LIBERO_LOG} 1 0 0 $PATH_MSG

fi

exit


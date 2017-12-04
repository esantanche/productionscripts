#!/bin/sh

# Questo script non manda critical ma solo info pero' le riporta sul log principale

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

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

Messaggio_dati () {

   echo Report periodico spazio libero rimasto segmento dati
   echo Nome db $NOMEDB
   echo Spazio rimasto $SPAZIO_LIBERO_DATI MB

}

#Messaggio_log_sotto_soglia () {
#
#   echo Db in situazione critica per mancanza di spazio intervenire urgentemente
#   echo Nome db $NOMEDB
#   echo Segmento critico LOG
#   echo Spazio rimasto $SPAZIO_LIBERO_LOG
#
#}

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

SPAZIO_LIBERO_DATI_GB=`expr $SPAZIO_LIBERO_DATI \/ 1024`

#SEGMAP=4

#SPAZIO_LIBERO_LOG=`isql -Utest -Ptestpwd -S$ASE_NAME -w400 << EOF | grep "LIBERO_MB" | awk '{ print int($2); }'
#begin
#declare @id_del_db smallint
#declare @Spazio_libero_Mb dec
#set nocount on
#select @id_del_db = dbid from sysdatabases where name like \"$NOMEDB\"
#select @Spazio_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256)) from sysusages where dbid=@id_del_db and segmap & $SEGMAP = $SEGMAP
#select \"LIBERO_MB\",@Spazio_libero_Mb
#end
#go
#quit
#EOF`

#echo SPAZIO_LIBERO_DATI=$SPAZIO_LIBERO_DATI
#echo SPAZIO_LIBERO_LOG=$SPAZIO_LIBERO_LOG
#SOGLIA_SPAZIO_LIBERO_DATI_MB=3000
#SOGLIA_SPAZIO_LIBERO_LOG_MB=4000

PATH_MSG=/tmp/.oggi/monitor_stat_db.msg

Messaggio_dati > $PATH_MSG    
#cat $PATH_MSG
#echo SPAZIO_LIBERO_DATI_GB=$SPAZIO_LIBERO_DATI_GB
sh $UTILITY_DIR/centro_unificato_messaggi.sh SPAZIO_DB ${NOMEDB}_DATI_${SPAZIO_LIBERO_DATI_GB}GB 0 0 0 $PATH_MSG

#if [ $SPAZIO_LIBERO_LOG -lt $SOGLIA_SPAZIO_LIBERO_LOG_MB ] ; then
#
#   Messaggio_log_sotto_soglia > $PATH_MSG    
#
#   sh $UTILITY_DIR/centro_unificato_messaggi.sh SPAZIO_DB ${NOMEDB}_LOG_${SPAZIO_LIBERO_LOG} 1 0 0 $PATH_MSG
#
#fi

exit


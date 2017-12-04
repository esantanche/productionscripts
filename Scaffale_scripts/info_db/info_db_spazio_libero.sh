#!/bin/sh
#

#****S* InfoDB/Info spazio libero db
#   NAME
#      info_db_spazio_libero Spazio libero dati e log di un db
#   USAGE
#      Utilizzo da linea comando per conoscere lo spazio libero per
#      la parte dati e la parte log di un db.
#   PURPOSE
#      Lo script esegue una query che calcola lo spazio libero netto per i segmenti
#      dati e log di un db quale si ottiene consultando la tabella sysusages
#      ma eseguendo in particolare le funzioni che consentono di conoscere i valori
#      correnti degli spazi liberi come presenti in RAM anche se la tabella sysusages
#      non e' stata ancora aggiornata.
#   HISTORY
#      Versione iniziale.
#   INPUTS
#      Va dato come paramtero il nome del database..
#   OUTPUT
#      L'output e' del tipo che segue:
#        Il database CAP_SVIL ha:
#             12206 MB di spazio libero per i dati
#             7968 MB di spazio libero per il log
#   RETURN VALUE
#      Nessuno
#   EXAMPLE
#      sh info_db_spazio_libero.sh CAP_SVIL
#   ERRORS
#      Viene ritornato un errore come messaggio a console se il nome del db
#      e' errato
#***

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d-%H:%M)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Il parametro su linea comando e' il nome del db
NOMEDB=$1

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db del quale si vuole conoscere la situazione degli spazi"
   echo "liberi."
   exit 1
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 1;
fi

Info_spazio_libero () {

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 <<EOF
begin
declare @id_del_db smallint
declare @Spazio_dati_libero_Mb dec
declare @Spazio_log_libero_Mb dec
set nocount on
select @id_del_db = dbid from sysdatabases where name like '$NOMEDB'
select @Spazio_dati_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256))  from sysusages where dbid=@id_del_db and segmap & 3 = 3
select @Spazio_log_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256))  from sysusages where dbid=@id_del_db and segmap & 4 = 4
select 'DATI_LIBERO_MB',@Spazio_dati_libero_Mb
select 'LOG_LIBERO_MB',@Spazio_log_libero_Mb
end
go
quit
EOF

}

Info_spazio_libero | nawk -v nomedb=$NOMEDB 'BEGIN { printf "Il database %s ha:\n",nomedb; }
       /DATI_LIBERO_MB/ { printf "%10d MB di spazio libero per i dati\n",$2; }
       /LOG_LIBERO_MB/  { printf "%10d MB di spazio libero per il log\n",$2; }' 


#!/bin/sh 

# Questo script carica un db su di un altro ripristinando pero' la
# tabella sysusers del db destinazione

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

clear
echo "Questo script rimarra' in uso per alcuni giorni finche'"
echo "non verra' sostituito definitivamente dallo script"
echo "loadmx_preservando_sysusers.sh che e' utilizzabile"
echo "da subito."
echo "  "
echo "ATTENZIONE se il db sorgente e' stato prodotto sulla macchina"
echo "mx2-prod-pridb, questo script non funzionera' in quanto i dump"
echo "prodotti su mx2-prod-pridb sono compressi con l'opzione"
echo "compress del comando dump, opzione non gestita da questo"
echo "script."
echo "  "
echo "Dare invio per continuare"
read

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db destinazione"
   echo "il dump del db sorgente deve avere path /sybased1/dump/DB_TO_LOAD.dmp"
   echo "quindi gia' unzippato"
   exit 0
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$1"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $1 " non esiste."
   exit 0
fi

clear
echo " " 
echo "Questo script carichera' sul db " $1 " il contenuto del dump /sybased1/dump/DB_TO_LOAD.dmp"
echo "L'ASE Server sul quale e' presente " $1 " e' " $ASE_NAME
echo " "
echo "Si presuppone che:"
echo " "
echo "1) Il parametro 'allow updates to system tables' sia impostato a 1"
echo " "
echo "2) Nessuno stia utilizzando il db"
echo " "
echo "3) Il db " $1 " e quello dal quale e' stato fatto il dump /sybased1/dump/DB_TO_LOAD.dmp"
echo "   abbiano la stessa dimensione e suddivisione dati/log"
echo "  "
echo "Verifiche:"
echo "  "
PARALLOWUPDATES=`
isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/allow/ { print $9; }'
sp_configure "allow updates to system tables"
go
exit
EOF`
#echo $PARALLOWUPDATES
if [ $PARALLOWUPDATES -eq 0 ] ; then
   echo "1- Il parametro 'allow updates to system tables' di configurazione del server"
   echo "vale 0 e deve invece essere impostato a 1 prima di effettuare il load." 
   echo "Effettuare l'impostazione poi ripetere la procedura."
   echo " "
   exit 0;
else
   echo "1- Parametro 'allow updates to system tables' correttamente impostato a 1."
fi

echo " "

NUMUTENTI=`
isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/UTENTICOLL/ { print $2; }'
select "UTENTICOLL",count(*) from sysdatabases d, sysprocesses p where d.dbid=p.dbid and d.name="$1"
go
exit
EOF`
#echo $NUMUTENTI
if [ $NUMUTENTI -gt 0 ] ; then
   echo "2- Ci sono " $NUMUTENTI " utenti collegati al db per cui non si puo'"
   echo "procedere con il load."
   echo "Bisogna chiedere agli utenti di scollegarsi per poi riprovare questa"
   echo "procedura."
   echo " "
   exit 0;
else
   echo "2- Nessun utente collegato al db."
fi

echo "  "
echo "3- Nota bene: il punto 3 dei prerequisiti va verificato manualmente!"
echo "  "

echo "Dare S poi invio per avviare l'operazione o N e invio per non proseguire"
read risposta
if [ $risposta != "S" ] ; then
   exit 0;
fi

echo "============================================================="
echo "Eseguo il bcp out di sysusers..."

bcp $1..sysusers out /sybase/utility/data/sysusers_db_to_trans.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp: " $ERR
   exit 1
fi

echo "============================================================="
echo "Eseguo il load e il delete della sysusers..."

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF 
load database $1 from "/sybased1/dump/DB_TO_LOAD.dmp"
go
online database $1
go
use $1
go
delete from sysusers
go
checkpoint
go
exit
EOF

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella load: " $ERR
   exit 1
fi

echo "============================================================="
echo "Eseguo il bcp in della sysusers salvata prima..."

bcp $1..sysusers in /sybase/utility/data/sysusers_db_to_trans.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER 

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp in: " $ERR
   exit 1
fi

chmod 660 /sybase/utility/data/sysusers_db_to_trans.bcp

echo "============================================================="
echo "Rimuovo il dmp caricato..."

rm /sybased1/dump/DB_TO_LOAD.dmp 

echo "============================================================="
echo "Operazione conclusa."

#echo Allineamento del db CAP_REPORT concluso

#load database CAP_REPORT from "/sybased1/dump/CAP_PROD_TO_LOAD.dmp"
#go
#online database CAP_REPORT
#go
#use CAP_REPORT
#go
#delete from sysusers
#go
#exit

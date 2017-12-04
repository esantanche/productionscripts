#!/bin/sh 
#

# dbccmx_alldb.sh
# Questo script esegue il check di integrità dei database Sybase presenti nel server ASE attivo sulla macchina sulla
# quale lo script viene eseguito.
# I check vengono effettuati mediante opportuni comandi dbcc eseguiti dallo script dbccmx_singolodb.sh che viene 
# richiamato per ogni database
# Si utilizza il file dbccmx_parametri che contiene i parametri di funzionamento di questo script, quali l'elenco dei
# database dei quali non va fatto il check

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

LISTA_DB_NODBCC=$1

# Questo e' il file generato dallo script dbccmx_singolodb.sh nelle diverse esecuzioni per i diversi db
FILE_ERRORI=$UTILITY_DIR/out/errori_ultima_esecuzione_dbcc

# Lettura del parametro DB_NO_DBCC dal file dei parametri
# Si tratta dell'elenco dei database da non sottoporre a check
DB_NODBCC=`grep DB_NO_DBCC${LISTA_DB_NODBCC} $UTILITY_DIR/dbccmx_parametri | cut -f 2 -d =`

#echo Lista db da non sottoporre a dbcc $DB_NODBCC     

# Cancello il file degli errori 
rm -f $FILE_ERRORI 1>/dev/null 2>&1


DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    
INIZIO_EPOCH=`epoch-it.pl`


# Eseguo lo script dbccmx_singolodb.sh per ogni database

# La variabile OKNONTROVATO dira' se per almeno un database non e' stata trovata la stringa OKDBCC nel
# file degli errori ($FILE_ERRORI), segnalando quindi che non sono stati fatti i check oppure che i check
# sono tutti in errore
OKNONTROVATO=0
NESSUNDB=1
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------|@'
set nocount on
go
select name from sysdatabases where name not in ($DB_NODBCC) order by name
go
EOF`
do
       #echo NOME DEL DB DA VEDERE $i
       sh $UTILITY_DIR/dbccmx_singolodb.sh $i 
       OKDBCC_CORRENTE=`grep "OKDBCC.*$i" $FILE_ERRORI | wc -l`
       if [ $OKDBCC_CORRENTE -eq 0 ] ; then
          OKNONTROVATO=1
       fi
       NESSUNDB=0
done


FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_EPOCH=`epoch-it.pl`

# Vedo se ci sono errori nel file degli errori
ERRORIDBCC=`grep "ERROREDBCC" $FILE_ERRORI | wc -l`
WARNSDBCC=`grep "WARNDBCC" $FILE_ERRORI | wc -l`


# Invio la mail di check eseguito con segnalazione di errore o no
CODICE_RITORNO=1
if [ $OKNONTROVATO -eq 1 -o $ERRORIDBCC -gt 0 -o $NESSUNDB -eq 1 ] ; then
   echo "Subject: [DBCCMX] ERRORE NEL DBCC SU "$ASE_NAME >  /tmp/dbccmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/dbccmx.mail
   echo "Ci sono errori nelle operazioni di dbcc "$DATA" sull'ASE "$ASE_NAME >> /tmp/dbccmx.mail
   echo "sulla macchina "`hostname` >> /tmp/dbccmx.mail
   echo "    " >> /tmp/dbccmx.mail
   echo "Esaminare gli errori e studiare le azioni correttive mediante comandi dbcc" >> /tmp/dbccmx.mail
   echo "===========================" >> /tmp/dbccmx.mail
   echo "File "$FILE_ERRORI >> /tmp/dbccmx.mail
   cat $FILE_ERRORI >> /tmp/dbccmx.mail
   CODICE_RITORNO=1
elif [ $WARNSDBCC -gt 0 ] ; then
   echo "Subject: [DBCCMX] Warning nel dbcc su "$ASE_NAME >  /tmp/dbccmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/dbccmx.mail
   echo "Non sono state effettuate alcune operazioni di dbcc "$DATA" sull'ASE "$ASE_NAME >> /tmp/dbccmx.mail
   echo "sulla macchina "`hostname` >> /tmp/dbccmx.mail
   echo "    " >> /tmp/dbccmx.mail
   echo "Ci sono operazioni di dbcc da ripetere" >> /tmp/dbccmx.mail
   echo "===========================" >> /tmp/dbccmx.mail
   echo "File "$FILE_ERRORI >> /tmp/dbccmx.mail
   cat $FILE_ERRORI >> /tmp/dbccmx.mail
   CODICE_RITORNO=1
else
   echo "Subject: [DBCCMX] Dbcc ok "$DATA" "$ASE_NAME" "$LISTA_DB_NODBCC  >  /tmp/dbccmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/dbccmx.mail
   echo "Dbcc "$DATA" eseguito regolarmente senza trovare errori sull'ASE "$ASE_NAME >> /tmp/dbccmx.mail
   echo "sulla macchina "`hostname` >> /tmp/dbccmx.mail
   echo "   " >> /tmp/dbccmx.mail
   CODICE_RITORNO=0
fi

if [ a$LISTA_DB_NODBCC = a ] ; then
   LISTA_DB_NODBCC=ALL
fi

#sh $UTILITY_DIR/centro_log_operazioni.sh DBCC $LISTA_DB_NODBCC $CODICE_RITORNO $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN
sh $UTILITY_DIR/centro_unificato_messaggi.sh DBCC $LISTA_DB_NODBCC $CODICE_RITORNO $INIZIO_EPOCH $FINE_EPOCH /tmp/dbccmx.mail

exit $CODICE_RITORNO;


#!/bin/sh 

# Questo script carica un db su di un altro ripristinando pero' la
# tabella sysusers del db destinazione

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

DUMP_DIR=$PATH_DUMP_DIR

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri il nome del db destinazione e il nome del file di dump"
   echo "presente in "$DUMP_DIR
   exit 0
fi

NOMEDB=$1
NOMEDUMP=$2 

if [ ! -f $DUMP_DIR/$NOMEDUMP ] ; then
   echo Dump $DUMP_DIR/$NOMEDUMP non esistente
   exit 0;
fi 

ZIPPATO_CON_GZIP=`echo $NOMEDUMP | grep gz | wc -l`

if [ $ZIPPATO_CON_GZIP -eq 1 ] ; then
   echo File zippato con gzip, unzippare prima di utilizzare questo script.
   # gunzip $DUMP_DIR/$NOMEDUMP
   exit 0;
fi 

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

clear

#######################################
# Controllo che sia impostato il parametro 'allow updates to system tables'
PARALLOWUPDATES=`
isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/allow/ { print $9; }'
sp_configure "allow updates to system tables"
go
exit
EOF`
#echo $PARALLOWUPDATES
echo " "
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

######################################################
# Controllo che nessuno stia utilizzando il db
NUMUTENTI=`
isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/UTENTICOLL/ { print $2; }'
select "UTENTICOLL",count(*) from sysdatabases d, sysprocesses p where d.dbid=p.dbid and d.name="$1"
go
exit
EOF`
#echo $NUMUTENTI
if [ $NUMUTENTI -gt 0 ] ; then
   echo "2- Ci sono " $NUMUTENTI " utenti collegati al db " $NOMEDB " per cui non si puo'"
   echo "   procedere con il load."
   # Qui tentiamo il kill delle sessioni aperte sul db
   echo " "
   echo "Dare S poi invio se si vogliono killare le sessioni aperte sul db"
   read risposta
   if [ $risposta != "S" ] ; then
      echo " "
      echo "Bisogna chiedere agli utenti di scollegarsi per poi riprovare questa"
      echo "procedura."
      echo " "
      exit 0;
   else
      # Eseguo il kill delle sessioni

      echo " "
      echo Kill sessions su $NOMEDB
      sh $UTILITY_DIR/kill_sessions.sh $NOMEDB
      ERRORE=$?
      if [ $ERRORE -gt 0 ] ; then
         echo Errore nella kill delle sessioni su $NOMEDB
         echo ==
      fi
      echo Eseguito kill sessions
      echo " "

   fi

   ######################################
   # Ricontrollo che non ci sia nessuno collegato
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
      exit 0;
   else
      echo "2- Nessun utente collegato al db."
   fi

else
   echo "2- Nessun utente collegato al db."
fi

echo " "
echo "=============================================================================="
echo " " 
echo "Questo script carichera' sul db " $NOMEDB " il contenuto del dump $DUMP_DIR/$NOMEDUMP"
echo "L'ASE Server sul quale e' presente " $NOMEDB " e' " $ASE_NAME
echo " "
echo "Si ricorda che:"
echo " "
echo "1) Il db " $NOMEDB " e quello dal quale e' stato fatto il dump "$DUMP_DIR"/"$NOMEDUMP
echo "   devono avere la stessa dimensione e suddivisione dati/log"
echo "2) Il dump, se compresso da sybase nel corso dell'operazione di dump deve avere"
echo "   estensione .cmp.dmp in modo tale che questo script possa procedere alla"
echo "   decompressione. La cosa migliore da fare e' non modificare in nessun modo"
echo "   il nome del file" 
echo "3) Il file di dump, dopo il caricamento, viene eliminato, previa conferma"
echo "  "
echo " "

echo "Dare S poi invio per avviare l'operazione o N e invio per non proseguire"
read risposta
if [ $risposta != "S" ] ; then
   exit 0;
fi

COMPRESSO_DA_SYBASE=`echo $NOMEDUMP | grep "[.]cmp[.]" | wc -l`
#echo Compresso da sybase $COMPRESSO_DA_SYBASE

if [ $COMPRESSO_DA_SYBASE -eq 1 ] ; then
   CLAUSOLA_COMPRESS="compress::"
else
   CLAUSOLA_COMPRESS=""
fi

echo "${CLAUSOLA_COMPRESS}$DUMP_DIR/$NOMEDUMP"

#exit 0;

echo "============================================================="
echo "Eseguo il bcp out di sysusers e sysalternates..."

bcp $NOMEDB..sysusers out $UTILITY_DIR/data/sysusers_db_to_trans.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp out sysusers: " $ERR
   exit 1
fi

bcp $NOMEDB..sysalternates out $UTILITY_DIR/data/sysalternates_db_to_trans.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp out sysalternates: " $ERR
   exit 1
fi

echo "============================================================="
echo "Eseguo il load e il delete della sysusers e della sysalternates..."
echo "  "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF 
load database $NOMEDB from "${CLAUSOLA_COMPRESS}$DUMP_DIR/$NOMEDUMP"
go
online database $NOMEDB
go
use $NOMEDB
go
if @@error = 0 delete from sysusers
go
checkpoint
go
if @@error = 0 delete from sysalternates
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
echo "Eseguo il bcp in della sysusers e della sysalternates salvate prima..."

bcp $NOMEDB..sysusers in $UTILITY_DIR/data/sysusers_db_to_trans.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER 

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp in sysusers: " $ERR
   exit 1
fi

bcp $NOMEDB..sysalternates in $UTILITY_DIR/data/sysalternates_db_to_trans.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER 

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp in sysalternates: " $ERR
   exit 1
fi

chmod 660 $UTILITY_DIR/data/sysusers_db_to_trans.bcp
chmod 660 $UTILITY_DIR/data/sysalternates_db_to_trans.bcp

echo "============================================================="
echo "Rimozione del dmp caricato..."
echo " "

echo "Dare S poi invio per cancellare il dump appena caricato, oppure N per non cancellarlo"
read risposta
if [ $risposta != "S" ] ; then
   echo "============================================================="
   echo "Operazione conclusa senza cancellare il dump."
   exit 0;
fi

rm -f $DUMP_DIR/$NOMEDUMP 

echo "============================================================="
echo "Operazione conclusa."


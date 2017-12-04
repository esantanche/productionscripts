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
   echo "Usage: dare come parametri il nome del db destinazione e il path completo del file contenente la prima"
   echo "stripe del dump. Per es. /syb_bkp_vari/dmpmx-MLC_CAP_TEST-20060312#1#.cmp.dmp"
   echo "Naturalmente nella stessa directory ci devono essere anche le altre stripe"
   exit 0
fi

NOMEDB=$1
NOMESTRIPE1=$2 

if [ ! -f $NOMESTRIPE1 ] ; then
   echo Dump $NOMESTRIPE1 non esistente
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
select "UTENTICOLL",count(*) from sysdatabases d, sysprocesses p where d.dbid=p.dbid and d.name="$NOMEDB"
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
select "UTENTICOLL",count(*) from sysdatabases d, sysprocesses p where d.dbid=p.dbid and d.name="$NOMEDB"
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
echo "Specchietto informazioni:"
echo "Nome dell'ASE:  "$ASE_NAME
echo "Nome del db:    "$NOMEDB 
echo "Prima stripe:   "$NOMESTRIPE1
echo " "
echo "Si ricorda che:"
echo " "
echo "1) Il db" $NOMEDB "deve essere di dimensione uguale o maggiore del db di partenza"
echo " "
echo "2) Questo script gestisce solo dump *COMPRESSI* e *DIVISI IN DUE O PIU STRIPE*"
echo " "
echo "3) I file di dump, dopo il caricamento, *NON* vengono eliminati"
echo " "
echo "4) Questo script lancia lo script loadmx_in_crontab_striped.multistripe.sh che quando finisce"
echo "   manda una mail"
echo "  "
echo " "

echo "Dare S poi invio per avviare l'operazione o N e invio per non proseguire"
read risposta
if [ $risposta != "S" ] ; then
   exit 0;
fi

echo "Lancio lo script loadmx_in_crontab_striped.multistripe.sh" $NOMEDB $NOMESTRIPE1
echo "Lo lancio con nohup e in background"
rm -f nohup.out
if [ $USER != sybase ] ; then
   su - sybase -c "nohup sh $UTILITY_DIR/loadmx_in_crontab_striped.multistripe.sh $NOMEDB $NOMESTRIPE1 &"
else 
   nohup sh $UTILITY_DIR/loadmx_in_crontab_striped.multistripe.sh $NOMEDB $NOMESTRIPE1 &
fi
#echo "Lanciato, questo ¨e' il nohup.out"
echo "Lanciato"

exit 


#!/bin/sh 
#

# dbccmx_singolodb.sh
# Esegue i check dbcc per un dato database
# Fa uso del file dbccmx_messaggi contenente i messaggi esplicativi degli errori
# Il nome del database sul quale eseguire i check e' passato come argomento
# Si eseguono: 
# Per i database configurati nel dbccdb:
#	checkstorage con successivo checkverify
#	checkcatalog
# Per i database *non* configurati nel dbccdb:
#      checkdb
#      checkalloc
#      checkcatalog
# Se un db risulta troppo grande per i check checkdb, checkalloc, ma non e' configurato
# nel dbccdb, ci si rifiuta di verificarlo

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

#############################################################
# Funzioni
#############################################################

##############################################################
# Questa funzione calcola la dimensione globale di un database
#
# Il nome del db e' in $NOMEDB e la dimensione in MB viene
# tornata in DIMENSIONE_DB_MB
# Come tutte le altre funzioni qui anche questa si basa su
# una dimensione di pagina di 4K
#
function calcola_dimensione_db {

   DIMENSIONE_DB_MB=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 <<EOF | awk '/DIMENSIONE_DB_MB/ { print $2; }'
begin
declare @id_del_db smallint
select @id_del_db = dbid from sysdatabases where name like '$NOMEDB'
select 'DIMENSIONE_DB_MB',sum(size / 256) from sysusages where dbid=@id_del_db
end
go
quit
EOF`

   #echo "funzione calcola_dimensione_db $NOMEDB $DIMENSIONE_DB_MB MB"

}

############################################################
# Questa funzione verifica se il database e' stato configurato nel dbccdb ovvero
# puo' essere verificato con il comando dbcc checkstorage
# In tal caso i check effettuati sul database saranno diversi 
# La funzione trova il nome del database nella variabile NOMEDB
# e ritorna l'esito della verifica nella variabile DB_CONFIGURATO_IN_DBCCDB
function verifica_configurazione_nel_dbccdb {
   #echo FN verifica_configurazione_nel_dbccdb

   # Le righe in cui type_code=6 nella tabella dbcc_config contengono nella colonna
   # stringvalue il nome dei database configurati 

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dbccmx_confdbccdb
set nocount on
use dbccdb
go
select 'NOMEDB  ',left(stringvalue,60),'  ' from dbcc_config where type_code=6      
go
quit
EOF

   #cat /tmp/dbccmx_confdbccdb
   #echo funzione verifica_configurazione_nel_dbccdb $NOMEDB

   DB_CONFIGURATO_IN_DBCCDB=`grep "NOMEDB.* $NOMEDB " /tmp/dbccmx_confdbccdb | wc -l`

   #echo funzione verifica_configurazione_nel_dbccdb $DB_CONFIGURATO_IN_DBCCDB

   rm -f /tmp/dbccmx_confdbccdb 1>/dev/null 2>&1
}

################################################################
# Questa funzione esegue il dbcc checkstorage
# 
# La funzione trova il nome del database nella variabile NOMEDB
# e ritorna ERRORE_CHECKSTORAGE=1 se non e' riuscita a fare il checkstorage
# mentre l'esito del checkstorage viene esaminato nella funzione analizza_risultato_checkstorage
function esegui_checkstorage {
   #echo FN esegui_checkstorage
   ERRORE_CHECKSTORAGE=0

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dbccmx_ckstorage
use dbccdb
go
sp_dbcc_deletehistory null,$NOMEDB
go 
if @@error != 0 select 'erroredbcccheckstorage'
go
dbcc checkstorage($NOMEDB)
go
if @@error != 0 select 'erroredbcccheckstorage'
go
quit
EOF

   # verifico:
   # che sia stato prodotto l'output /tmp/dbccmx_ckstorage
   # che l'output contenga la stringa Storage checks ... are complete che indica il completamento del checkstorage
   # che non appaia nell'output la stringa erroredbcccheckstorage che appare se c'e' errore nell'esecuzione del checkstorage
   if [ ! -s /tmp/dbccmx_ckstorage ] ; then
      ERRORE_CHECKSTORAGE=1
   else
      if [ `grep "Storage checks for.*are complete" /tmp/dbccmx_ckstorage | wc -l` -eq 0 ] ; then
         ERRORE_CHECKSTORAGE=1
      else
         if [ `grep "erroredbcccheckstorage" /tmp/dbccmx_ckstorage | wc -l` -eq 1 ] ; then
            ERRORE_CHECKSTORAGE=1
         fi
      fi
   fi

   #cat /tmp/dbccmx_ckstorage
   rm -f /tmp/dbccmx_ckstorage 1>/dev/null 2>&1
}

################################################################
# Questa funzione esegue il checkverify che andiamo appunto ad eseguire dopo
# il checkstorage 
# La funzione trova il nome del database nella variabile NOMEDB
# e ritorna ERRORE_CHECKVERIFY=1 se non e' riuscita a fare il checkverify
function esegui_checkverify {
   #echo FN esegui_checkverify
   ERRORE_CHECKVERIFY=0

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dbccmx_ckverify
dbcc checkverify($NOMEDB)
go
if @@error != 0 select 'erroredbcccheckverify'
go
quit
EOF

   # verifico:
   # che sia stato prodotto l'output /tmp/dbccmx_ckverify
   # che l'output contenga la stringa DBCC CHECKVERIFY for database ... completed che indica il completamento del checkverify
   # che non appaia nell'output la stringa erroredbcccheckverify che appare se c'e' errore nell'esecuzione del checkverify
   if [ ! -s /tmp/dbccmx_ckverify ] ; then
      ERRORE_CHECKVERIFY=1
   else
      if [ `grep "DBCC CHECKVERIFY for database.*completed" /tmp/dbccmx_ckverify | wc -l` -eq 0 ] ; then
         ERRORE_CHECKVERIFY=1
      else
         if [ `grep "erroredbcccheckverify" /tmp/dbccmx_ckverify | wc -l` -eq 1 ] ; then
            ERRORE_CHECKVERIFY=1
         fi
      fi
   fi

   rm -f /tmp/dbccmx_ckverify 1>/dev/null 2>&1
}

###################################################################
# Questa funzione analizza il risultato del checkstorage e del checkverify
# andando a cercare il numero di "hard faults" trovati dal checkstorage e confermati
# dal checkverify 
# La funzione trova il nome del database nella variabile NOMEDB
# e ritorna ERRORE_ANALIZZA_CHECKSTORAGE=1 se c'e' stato un problema nell'esecuzione
# della query. In caso di esecuzione senza problemi, ritorna la variabile NUMHARDFAULTS
# che e' il numero di hard faults trovati, che puo' essere zero o diverso da zero
function analizza_risultato_checkstorage {
   # In realta' qui analizziamo il risultato del checkverify fatto dopo il checkstorage
   #echo FN analizza_risultato_checkstorage

   # Dinamica della query:
   # 1) Ricavo il dbid del database che mi servira' nelle query successive
   # 2) Ottengo il massimo numero di operazione di checkstorage/checkverify eseguita. Quindi, avendo fatto come ultima operazione
   #     un checkverify, ottengo appunto il numero di operazione di tale checkverify (variabile @mxopid)
   # 3) Ricavo i risultati di tale operazione dalla tabella dbcc_operation_results e in particolare appunto il numero di hard faults
   #     trovati individuato dal codice di tipo 1000
   # optype vale 3 per le operazioni di checkverify; nella query di dbcc_operation_results devo ripetere il vincolo sul dbid perche'
   # i numeri di operazione non sono globalmente univoci ma sono univoci solo per un dato database
   isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dbccmx_anlcheckverify
use dbccdb
go
declare @mxopid int, @dbi int
select @dbi = dbid from master..sysdatabases where name='$NOMEDB'
select @mxopid = max(opid) from dbcc_operation_log where optype=3 and dbid=@dbi
select @dbi, @mxopid
select 'NUMHARDFAULTS', intvalue 
from dbcc_operation_results
where type_code=1000 and opid=@mxopid and optype=3 and dbid=@dbi
go
quit
EOF

   # Se non trovo la stringa NUMHARDFAULTS nell'output vuol dire che la query non e' riuscita
   # altrimenti posso ricavare il numero di hard faults trovati
   if [ `grep NUMHARDFAULTS /tmp/dbccmx_anlcheckverify | wc -l` -eq 0 ] ; then
      ERRORE_ANALIZZA_CHECKSTORAGE=1
   else
      ERRORE_ANALIZZA_CHECKSTORAGE=0     
      NUMHARDFAULTS=`grep NUMHARDFAULTS /tmp/dbccmx_anlcheckverify | awk '{ print $2; }' `
   fi

   #cat /tmp/dbccmx_anlcheckverify
   rm -f /tmp/dbccmx_anlcheckverify 1>/dev/null 2>&1

}

################################################################
# Questa funzione esegue un check diverso dal checkstorage o dal checkverify, check il cui
# nome viene passato dalla variabile TIPO_CHECK
# Puo' trattarsi quindi di un checkdb, di un checkalloc ecc.
# Il nome del database e' nella variabile NOMEDB
# La variabile di ritorno ERRORE_CHECKDIVERSI indica se il check e' stato eseguito o no
# La variabile NUMERRDBCCTROVATI indica, se il check e' stato eseguito, quante righe
# dell'output del check contengono le stringhe Err o err o Msg
# Vanno evitate le stringhe:
# "If DBCC printed error messages" che appare sempre alla fine dell'output
# "sp_setsuspect_error" che appare sempre quando si fa il check del db sybsystemprocs ma non e' un errore ma il nome di
# una stored procedure
# ..........????
function esegui_checkdiversi {
   #echo FN esegui_checkdiversi

   # TIPO_CHECK contiene il nome del check da eseguire

   ERRORE_CHECKDIVERSI=1
   TENTATIVI=5 # Numero di tentativi di ripetizione del check da fare 
   NUMERRDBCCTROVATI=0

   while [ $TENTATIVI -gt 0 -a \( $ERRORE_CHECKDIVERSI -gt 0 -o  $NUMERRDBCCTROVATI -gt 0 \) ] ; do

      isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dbccmx_ckdiversi_$TIPO_CHECK
dbcc $TIPO_CHECK($NOMEDB)
go
quit
EOF

      # verifico:
      # che sia stato prodotto l'output /tmp/dbccmx_ckdiversi_$TIPO_CHECK
      # che l'output contenga la stringa DBCC execution completed che indica il completamento del check
      # che non appaia nell'output la stringa erroredbcccheckdiversi che appare se c'e' errore nell'esecuzione del check
      ERRORE_CHECKDIVERSI=0
      NUMERRDBCCTROVATI=0
      if [ ! -s /tmp/dbccmx_ckdiversi_$TIPO_CHECK ] ; then
         ERRORE_CHECKDIVERSI=1
      else
         if [ `grep "DBCC execution completed" /tmp/dbccmx_ckdiversi_$TIPO_CHECK | wc -l` -eq 0 ] ; then
            ERRORE_CHECKDIVERSI=1
         else
	    # Cerco segnalazioni di errore nell'output ma evitando la riga finale che c'e' sempre e
	    # contiene la stringa 'error' - evito anche la stringa "sp_setsuspect_error" che e' il nome di una
            # stored procedure e non un errore
          
            # Questo e' il messaggio che ignoriamo
            # Msg 12947, Level 16, State 1:
            # Server 'MX1_DEV_2', Line 1:
            # Syslogs free space is currently 97163 pages but DBCC counted 127499 pages. 
            # This descrepancy may be spurious if this count was done in multi-user mode. 
            # Please run DBCC TABLEALLOC(syslogs, full, fix) to correct it.

            # Questa versione del check degli errori ignora gli errori di tipo Msg 12947 che sono frequenti
            #NUMERRDBCCTROVATI=`grep -E "Err|err|Msg"  /tmp/dbccmx_ckdiversi_$TIPO_CHECK  | grep -v "If DBCC printed error messages" | grep -v "sp_setsuspect_error" | grep -v "Msg 12947" | wc -l`
            # Questa versione invece non ignora gli errori di cui sopra
            NUMERRDBCCTROVATI=`grep -E "Err|err|Msg"  /tmp/dbccmx_ckdiversi_$TIPO_CHECK  | grep -v "If DBCC printed error messages" | grep -v -E "sp_setsuspect_errori|TES_ErroriQuadratura_DBF" | wc -l`
            #grep -E "Err|err|Msg"  /tmp/dbccmx_ckdiversi
         fi
      fi

      TENTATIVI=`expr $TENTATIVI - 1`   
      #echo Tentativi $TENTATIVI errcheckdiv $ERRORE_CHECKDIVERSI

   done

   #rm -f /tmp/dbccmx_ckdiversi 1>/dev/null 2>&1
}

################################################################
# Questa funzione scrive nel file di path $FILE_ERRORI un messaggio di errore oppure 
# di ok se il codice di errore e' zero
# La variabile CODICE_ERRORE contiene il codice di errore
# Il messaggio esplicativo dell'errore viene letto dal file dbccmx_messaggi 
function segnalazione_errore {
   #echo FN segnalazione_errore

   DATA=$(/usr/bin/date +%Y%m%d-%H%M)
   if [ $CODICE_ERRORE -gt 10 ] ; then
      echo "=====ERROREDBCC===========" >> $FILE_ERRORI
      echo $DATA >> $FILE_ERRORI
      echo $NOMEDB >> $FILE_ERRORI
      echo Codice errore $CODICE_ERRORE >> $FILE_ERRORI
      # Prelevo il messaggio di errore dal file dei messaggi
      grep "^${CODICE_ERRORE} " $UTILITY_DIR/dbccmx_messaggi >> $FILE_ERRORI
   elif [ $CODICE_ERRORE -gt 0 ] ; then
      echo "=====WARNDBCC===========" >> $FILE_ERRORI
      echo $DATA >> $FILE_ERRORI
      echo $NOMEDB >> $FILE_ERRORI
      echo Codice errore $CODICE_ERRORE >> $FILE_ERRORI
      # Prelevo il messaggio di errore dal file dei messaggi
      grep "^${CODICE_ERRORE} " $UTILITY_DIR/dbccmx_messaggi >> $FILE_ERRORI
   else
      echo OKDBCC $NOMEDB $DATA >> $FILE_ERRORI
   fi
}

###################################################################
# Main
###################################################################

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db di cui eseguire il dbcc"
   exit 0
fi

# Parametri da passare: nome del db
NOMEDB=$1

#echo dbccmx_singolodb $NOMEDB

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

# File che conterra' le segnalazioni relative a tutti i db esaminati
# Questo script non deve quindi cancellare questo file, ci pensera' il chiamante dbccmx_alldb.sh
FILE_ERRORI=$UTILITY_DIR/out/errori_ultima_esecuzione_dbcc

################################################
# ANALISI CONFIGURAZIONE DEL DB DEL DBCCDB
# Qui verifichiamo se il db e' configurato nel dbccdb

DB_CONFIGURATO_IN_DBCCDB=0
verifica_configurazione_nel_dbccdb
#echo dbccmx_singolodb nomedb $NOMEDB config in dbccdb $DB_CONFIGURATO_IN_DBCCDB

calcola_dimensione_db

if [ $DB_CONFIGURATO_IN_DBCCDB -ne 1 -a  $DIMENSIONE_DB_MB -gt 5000 ] ; then
   # Il db non e' configurato nel dbccdb ma e' troppo grande
   # per essere esaminato con il checkdb
   # non procediamo al check
   echo Db troppo grande ma non configurato nel dbccdb
   CODICE_ERRORE=15
   segnalazione_errore
   exit $CODICE_ERRORE
fi

#####################################################
# Esecuzione dei dbcc separando quelli da eseguire per i db configurati
# nel dbccdb, da quelli non configurati

if [ $DB_CONFIGURATO_IN_DBCCDB -eq 1 ] ; then
   ##################################################
   # CASO DB CONFIGURATO NEL DBCCDB
   # Devo fare il checkstorage seguito dal checkverify
   # Il checkcatalog e' eseguito in entrambi i casi, fuori dell'if
   #echo Db configurato nel dbccdb
   #echo Eseguo il dbcc checkstorage
   esegui_checkstorage
   if [ $ERRORE_CHECKSTORAGE -eq 1 ] ; then
      # Il checkstorage non e' stato eseguito correttamente
      echo Errore nel checkstorage
      CODICE_ERRORE=1
      segnalazione_errore
   else
      # Il checkstorage e' stato eseguito correttamente, dobbiamo eseguire il checkverify
      #echo Checkstorage ok
      esegui_checkverify
      if [ $ERRORE_CHECKVERIFY -eq 1 ] ; then
         # Il checkverify non e' stato eseguito correttamente
         echo Errore nel checkverify
	 CODICE_ERRORE=2
         segnalazione_errore
      else
         # Il checkverify e' stato eseguito correttamente, analizziamo il risultato
	 # per avere il numero di hard faults trovati
         #echo Checkverify ok
	 analizza_risultato_checkstorage
         if [ $ERRORE_ANALIZZA_CHECKSTORAGE -eq 1 ] ; then
	    # L'analisi del risultato del checkverify non e' riuscita
	    echo Errore nell analisi del risultato del checkverify
            CODICE_ERRORE=3
            segnalazione_errore
	 else
	    # Analisi riuscita, abbiamo il numero di hard faults trovati
	    #echo Numero di hard faults trovati: $NUMHARDFAULTS
	    if [ $NUMHARDFAULTS -gt 0 ] ; then
	       CODICE_ERRORE=11
               segnalazione_errore
	    else
	       CODICE_ERRORE=0
	       segnalazione_errore
	    fi
	 fi
      fi
   fi
else
   ##################################################
   # CASO DB NON CONFIGURATO NEL DBCCDB
   # Devo fare checkdb checkalloc checkcatalog
   #echo Db non configurato nel dbccdb

   # Eseguo il checkdb
   #echo checkdb
   TIPO_CHECK="checkdb"
   esegui_checkdiversi
   if [ $ERRORE_CHECKDIVERSI -eq 1 ] ; then
      # Il checkdb non e' riuscito
      echo Errore nel checkdb
      CODICE_ERRORE=4
      segnalazione_errore
   else
      # Il checkdb e' riuscito e la variabile $NUMERRDBCCTROVATI contiene il numero di
      # errori trovati nel database, zero o diverso da zero
      #echo Numero di errori dbcc trovati in checkdb: $NUMERRDBCCTROVATI
      if [ $NUMERRDBCCTROVATI -gt 0 ] ; then
         CODICE_ERRORE=12
         segnalazione_errore
      else
         CODICE_ERRORE=0
         segnalazione_errore
      fi
   fi

   # Eseguo il checkalloc
   #echo checkalloc
   TIPO_CHECK="checkalloc"
   esegui_checkdiversi
   if [ $ERRORE_CHECKDIVERSI -eq 1 ] ; then
      echo Errore nel checkalloc
      CODICE_ERRORE=5
      segnalazione_errore
   else
      #echo Numero di errori dbcc trovati in checkalloc: $NUMERRDBCCTROVATI
      if [ $NUMERRDBCCTROVATI -gt 0 ] ; then
         CODICE_ERRORE=13
         segnalazione_errore
      else
         CODICE_ERRORE=0
         segnalazione_errore
      fi
   fi

fi # se il db e' configurato nel dbccdb

# Eseguo il checkcatalog che vale per tutti i database, sia quelli configurati nel dbccdb, sia per quelli non configurati
#echo checkcatalog
TIPO_CHECK="checkcatalog"
esegui_checkdiversi
if [ $ERRORE_CHECKDIVERSI -eq 1 ] ; then
   echo Errore nel checkcatalog
   CODICE_ERRORE=6
   segnalazione_errore
else
   #echo Numero di errori dbcc trovati in checkcatalog: $NUMERRDBCCTROVATI
   if [ $NUMERRDBCCTROVATI -gt 0 ] ; then
      CODICE_ERRORE=14
      segnalazione_errore
   else
      CODICE_ERRORE=0
      segnalazione_errore
   fi
fi

#echo codice errore $CODICE_ERRORE

exit $CODICE_ERRORE


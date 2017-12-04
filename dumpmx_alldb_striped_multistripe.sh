#!/bin/sh 
#

. /home/sybase/.profile

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

NUMERO_REPORT_PRESENTI=`ls -1tr $PATH_DUMP_DIR/dmpmx-*.rep 2>/dev/null | wc -l`

#echo $NUMERO_REPORT_PRESENTI

if [ $NUMERO_REPORT_PRESENTI -ge 9 ] ; then
   #echo Cancello i due piu vecchi
   rm -f `ls -1tr $PATH_DUMP_DIR/dmpmx-*.rep | head -1`
   rm -f `ls -1tr $PATH_DUMP_DIR/dmpmx-*.rep | head -1`
fi

# Cleanup immondizia
# Si tratta di cancellare tutti i file del file system /sybased1
# (tutto il file system) che non hanno il NODELETE in un .rep
# Cancello tutti i file per i quali *non* trovo in nessun file *.rep
# la stringa 'NODELETE' seguita dal nome del file stesso
for j in `find $PATH_DUMP_FS ! -type d | grep -v .rep | grep -v LEGGIMI`
do
   #echo ==================================================
   #echo $j
   nome_file=`basename $j`
   #echo $nome_file
   file_trovato=`cat $PATH_DUMP_DIR/*.rep | grep NODELETE | grep $nome_file | awk '{ print $2; }' | uniq`
   #echo File trovato $file_trovato
   if [ a$file_trovato != a$nome_file ] ; then
      # cancello
      # echo Cancello $j
      #echo Ho disattivato la cancellazione dell'immondizia
      rm -f $j
   fi
done 

# deve segnalare chiaramente se non ha funzionato
# deve fare compress::6 senza gzip tanto h uguale
# deve fare un test per vedere se c'i il DUMP is complete
# deve salvare con la data nel filename e cancellare il piu vecchio
#	mantenendone comunque un tot, non ho piu il numero progressivo
# deve mandare un messaggio se e' tutto ok e anche uno se qualcosa 
#	non funziona (ci pensa lo script che chiama questo)
# gli script di controllo dello spazio di manovra non servono piu'
# il nome del dump: dmpmx-<nomedb>-aaaammgg.cmp.dmp
# la data e' quella del momento in cui lo script di dump (quello che chiama questo) parte in modo da essere
#	sempre la stessa

DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    
INIZIO_EPOCH=`epoch-it.pl`

#export UTILITY_DIR=/sybase/utility
#export SAUSER=sa
#export SAPWD=capdevpwd
#export NOTSAUSER=test
#export NOTSAPWD=test
#export ASE_NAME=MX1_DEV_2
#export HOME_OF_SYBASE=/home/sybase
#export PATH_ERRORLOG_ASESERVER=/sybase/ASE-12_5/install/MX1_DEV_2.log 
#export PATH_ERRORLOG_BACKUPSERVER=/sybase/ASE-12_5/install/MX1_DEV_2_back.log
#export SOGLIA_FS_DUMP_MB=1000
#export SOGLIA_FS_DB_MB=3000
#export PATH_INSTALLDIR=/sybase/ASE-12_5/install

# Nel parametro di input $1 ci trovo quale lista di db da non dumpare devo usare
LISTA_DB_NODUMP=$1

#if [ a$LISTA_DB_NODUMP = a ] ; then
#   echo Lista db standard
#   DB_NODUMP=`grep DB_DA_NON_DUMPARE= $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
#else
#   DB_NODUMP=`grep DB_DA_NON_DUMPARE${LISTA_DB_NODUP}= $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
#fi

DB_NODUMP=`grep DB_DA_NON_DUMPARE${LISTA_DB_NODUMP}= $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`

#echo Db da non dumpare $DB_NODUMP

rm -f $PATH_DUMP_DIR/dmpmx-$DATA.rep 2>/dev/null
rm -f $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb 2>/dev/null

NUMERODB=0
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v "name|----------|@"
set nocount on
go
select name from sysdatabases where name not in ($DB_NODUMP) order by name
go
EOF`
do
       sleep 10
       #echo Db $i chiamo dumpmx_singolodb_striped_multistripe.sh ===========
       sh $UTILITY_DIR/dumpmx_singolodb_striped_multistripe.sh $i $DATA
       sleep 20
       #echo $i
       NUMERODB=`expr $NUMERODB + 1`
done

#echo $NUMERODB

# Esaminare il report
NUMERO_RIGHE_REPORT=`cat $PATH_DUMP_DIR/dmpmx-$DATA.rep | grep Completo 2>/dev/null | wc -l`
ERRORI_NEL_REPORT=`grep Errore $PATH_DUMP_DIR/dmpmx-$DATA.rep 2>/dev/null | wc -l`

#echo numero righe report $NUMERO_RIGHE_REPORT
#echo errori $ERRORI_NEL_REPORT

FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_EPOCH=`epoch-it.pl`

#NUMERO_RIGHE_REPORT=1
#ERRORI_NEL_REPORT=1
CODICE_RITORNO=1
if [ $NUMERO_RIGHE_REPORT -ne $NUMERODB -o $ERRORI_NEL_REPORT -gt 0 ] ; then
   echo Dump errato $DATA > $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb 
   echo "Subject: [DUMPMX] ERRORE NEL DUMP SU "$ASE_NAME >  /tmp/dumpmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/dumpmx.mail
   echo "Si e' verificato un errore sul dump "$DATA" dell'ASE "$ASE_NAME >> /tmp/dumpmx.mail
   echo "sulla macchina "`hostname` >> /tmp/dumpmx.mail
   echo "    " >> /tmp/dumpmx.mail
   echo "Provvedere immediatamente a rifare il dump lanciando lo script dumpmx_alldb.sh" >> /tmp/dumpmx.mail
   echo "presente nella directory /sybase/utility loggandosi con l'utenza sybase" >> /tmp/dumpmx.mail
   CODICE_RITORNO=1
else
   echo Dump ok $DATA > $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb
   echo "Subject: [DUMPMX] Dump ok "$DATA" "$ASE_NAME" "$LISTA_DB_NODUMP  >  /tmp/dumpmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/dumpmx.mail
   echo "Dump "$DATA" eseguito regolarmente sull'ASE "$ASE_NAME >> /tmp/dumpmx.mail
   echo "sulla macchina "`hostname` >> /tmp/dumpmx.mail
   echo "   " >> /tmp/dumpmx.mail
   CODICE_RITORNO=0
fi

if [ a$LISTA_DB_NODUMP = a ] ; then
   LISTA_DB_NODUMP=ALL
fi

#sh $UTILITY_DIR/centro_log_operazioni.sh DUMP $LISTA_DB_NODUMP $CODICE_RITORNO $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN
sh $UTILITY_DIR/centro_unificato_messaggi.sh DUMP $LISTA_DB_NODUMP $CODICE_RITORNO $INIZIO_EPOCH $FINE_EPOCH /tmp/dumpmx.mail
rm -f /tmp/dumpmx.mail

exit $CODICE_RITORNO;



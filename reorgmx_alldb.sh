#!/bin/sh 
#

# reorgmx_alldb.sh
# Questo script esegue il reorg rebuild oppure l'update statistics delle tabelle di tutti i database
# salvo alcune esclusioni
# Se viene passato come parametro '-u' si esegue solo l'update statistics, altrimenti si fa il reorg rebuild
# Questo script richiama lo script reorgmx_singolodb.sh per ogni db 
# Si utilizza il file reorgmx_parametri che contiene i parametri di funzionamento di questo script, per ora solo l'elenco dei
# database dei quali non va fatto il reorg (o l'update statistics)

. /home/sybase/.profile

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

DATA=$(/usr/bin/date +%Y%m%d)

SOLO_UPDATE=0
if [ $1a = -ua ] ; then
   echo Solo update
   SOLO_UPDATE=1
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Lettura del parametro DB_NO_REORG dal file dei parametri
# Si tratta dell'elenco dei database da non sottoporre a reorg
DB_NOREORG=`grep DB_NO_REORG $UTILITY_DIR/reorgmx_parametri | cut -f 2 -d =`

INIZIO_ORE=$(/usr/bin/date +%H)
INIZIO_MIN=$(/usr/bin/date +%M)
INIZIO_EPOCH=`epoch-it.pl`

#echo $DB_NOREORG    
#echo Reorg rebuild $ASE_NAME

# Ho provato che il codice di errore torna quando chiamo gli script con sh

# Eseguo lo script reorgmx_singolodb.sh per ogni database

OUTPUT_SINGOLI_REORG=/tmp/.oggi/output_singoli_reorg

touch $OUTPUT_SINGOLI_REORG

TROVATO_ERRORE=0
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------|@'
set nocount on
go
select name from sysdatabases where name not in ($DB_NOREORG) order by name
go
EOF`
do
       #echo NOME DEL DB DA VEDERE $i
       if [ $SOLO_UPDATE -eq 1 ] ; then
          sh $UTILITY_DIR/reorgmx_singolodb.sh $i -u   >>  $OUTPUT_SINGOLI_REORG
          ERRORE=$?
       else
          sh $UTILITY_DIR/reorgmx_singolodb.sh $i      >>  $OUTPUT_SINGOLI_REORG
          ERRORE=$?
       fi
       if [ $ERRORE -gt 0 ] ; then
          TROVATO_ERRORE=1
          break
       fi
done

FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_EPOCH=`epoch-it.pl`

# Invio la mail di check eseguito con segnalazione di errore o no
CODICE_RITORNO=1
if [ $TROVATO_ERRORE -eq 1 ] ; then
   echo "Subject: [REORGMX] ERRORE NEL REORG SU "$ASE_NAME >  /tmp/reorgmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/reorgmx.mail
   echo "Ci sono errori nelle operazioni di reorg "$DATA" sull'ASE "$ASE_NAME >> /tmp/reorgmx.mail
   echo "sulla macchina "`hostname` >> /tmp/reorgmx.mail
   cat $OUTPUT_SINGOLI_REORG >> /tmp/reorgmx.mail
   echo "    " >> /tmp/reorgmx.mail
   CODICE_RITORNO=1
else
   echo "Subject: [REORGMX] Reorg ok "$DATA" "$ASE_NAME  >  /tmp/reorgmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/reorgmx.mail
   echo "Reorg "$DATA" eseguito regolarmente sull'ASE "$ASE_NAME >> /tmp/reorgmx.mail
   echo "sulla macchina "`hostname` >> /tmp/reorgmx.mail
   cat $OUTPUT_SINGOLI_REORG >> /tmp/reorgmx.mail
   echo "   " >> /tmp/reorgmx.mail
   CODICE_RITORNO=0
fi

#sh $UTILITY_DIR/centro_log_operazioni.sh REORG ALL $CODICE_RITORNO $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN
sh $UTILITY_DIR/centro_unificato_messaggi.sh REORG ALL $CODICE_RITORNO $INIZIO_EPOCH $FINE_EPOCH /tmp/reorgmx.mail

exit $CODICE_RITORNO;



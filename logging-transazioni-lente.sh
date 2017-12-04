#!/bin/sh -x
#

# Ogni volta che si trovano dei processi in lock sleep il punteggio si aumenta di PUNTI_PER_PROC_IN_LOCK_SLEEP
# mentre ogni minuto si diminuisce di 1
# Si da' l'allarme quando si superano i PUNTEGGIO_ALLARME punti
# Se il punteggio supera LIMITE_PUNTEGGIO lo si riporta a tale valore per evitare che cresca troppo e che
# quindi impieghi molto tempo per ridiscendere

TEMPO_LIMITE=15

. /home/sybase/.profile

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

PATH_LOG=$UTILITY_DIR/logs/logging-transazioni-lente.log

DATA=$(/usr/bin/date +%Y.%m.%d-%H:%M:%S)

# proclock.sh   
# select \"NUMEROCONNESSIONI\",count(*) from sysprocesses where suid != 0

NUMERO_TX_LENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 <<EOF | awk '/NUMERO_TX_LENTE/{ print $2; }'
set nocount on
go
select 'NUMERO_TX_LENTE',count(*) from systransactions where datediff(mi,starttime,getdate()) > $TEMPO_LIMITE
go
quit
EOF`

if [ a$NUMERO_TX_LENTE = a ] ; then
   echo $DATA Problemi di connessione >> $PATH_LOG
   exit
fi

if [ $NUMERO_TX_LENTE -gt 0 ] ; then
   echo $DATA Presenti $NUMERO_TX_LENTE transazioni in esecuzione da almeno $TEMPO_LIMITE minuti >> $PATH_LOG   
   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 <<EOF | awk '/TXLENTA/{ printf "    %-10s-%-10s %6d %-40s\n",$2,$3,$4,$5; }'  >> $PATH_LOG
set nocount on
go
select 'TXLENTA',
       convert(varchar(11),starttime,102),
       convert(varchar(10),starttime,108), spid, xactname 
       from systransactions 
       where datediff(mi,starttime,getdate()) > $TEMPO_LIMITE
go
quit
EOF

fi

# select 'TXLENTA',starttime, spid, xactname from systransactions where datediff(mi,starttime,getdate()) > $TEMPO_LIMITE

exit


#!/bin/sh -x
#

# Ogni volta che si trovano dei processi in lock sleep il punteggio si aumenta di PUNTI_PER_PROC_IN_LOCK_SLEEP
# mentre ogni minuto si diminuisce di 1
# Si da' l'allarme quando si superano i PUNTEGGIO_ALLARME punti
# Se il punteggio supera LIMITE_PUNTEGGIO lo si riporta a tale valore per evitare che cresca troppo e che
# quindi impieghi molto tempo per ridiscendere
PUNTI_PER_PROC_IN_LOCK_SLEEP=3
PUNTEGGIO_ALLARME=20
LIMITE_PUNTEGGIO=40

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

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

# proclock.sh   
# select \"NUMEROCONNESSIONI\",count(*) from sysprocesses where suid != 0

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/lock_finder.procs <<EOF
set nocount on
go
select 'SPID_LOCK_SLEEP',count(*) from sysprocesses where status='lock sleep' 
go
quit
EOF

RISULTATO_OTTENUTO=`grep SPID_LOCK_SLEEP /tmp/lock_finder.procs | wc -l`

if [ $RISULTATO_OTTENUTO -eq 0 ] ; then
   exit 0
fi

NUMERO_PROCESSI_IN_LOCK_SLEEP=`grep SPID_LOCK_SLEEP /tmp/lock_finder.procs | awk '{ print $2; }'`

#echo $NUMERO_PROCESSI_IN_LOCK_SLEEP

PUNTEGGIO_LOCK_SLEEP=`grep PUNTEGGIO_LOCK_SLEEP $UTILITY_DIR/lock-sleep-finder-parameters | cut -f 2 -d =`

if [ $PUNTEGGIO_LOCK_SLEEP'x' = 'x' ] ; then
   PUNTEGGIO_LOCK_SLEEP=`expr $PUNTEGGIO_ALLARME + 10`
fi

# Ogni volta che questo script viene eseguito e quindi ogni minuto
# il punteggio scende di uno
if [ $PUNTEGGIO_LOCK_SLEEP -gt 0 ] ; then
   PUNTEGGIO_LOCK_SLEEP=`expr $PUNTEGGIO_LOCK_SLEEP - 1`
fi

if [ $PUNTEGGIO_LOCK_SLEEP -gt $LIMITE_PUNTEGGIO ] ; then
   PUNTEGGIO_LOCK_SLEEP=$LIMITE_PUNTEGGIO
fi

# Se ci sono processi in lock sleep aumento il punteggio del parametro PUNTI_PER_PROC_IN_LOCK_SLEEP
if [ $NUMERO_PROCESSI_IN_LOCK_SLEEP -gt 0 ] ; then
   PUNTEGGIO_LOCK_SLEEP=`expr $PUNTEGGIO_LOCK_SLEEP + $PUNTI_PER_PROC_IN_LOCK_SLEEP`
   echo $DATA ===================================== > $UTILITY_DIR/out/lock-sleep-finder-log-detail
isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >> $UTILITY_DIR/out/lock-sleep-finder-log-detail <<EOF
set nocount on
go
select * from sysprocesses where status='lock sleep'
go
select * from syslocks
go
quit
EOF
fi

echo PUNTEGGIO_LOCK_SLEEP"="$PUNTEGGIO_LOCK_SLEEP > $UTILITY_DIR/lock-sleep-finder-parameters 

# Se il punteggio e' maggiore di PUNTEGGIO_ALLARME devo dare il critical altrimenti lo tolgo
if [ $PUNTEGGIO_LOCK_SLEEP -gt $PUNTEGGIO_ALLARME ] ; then
   # Do' critical
   echo "Esaminare i lock, puo' esserci un processo bloccato" > /tmp/lock-sleep-finder.nagiosrep
   echo "Punteggio lock raggiunto: "$PUNTEGGIO_LOCK_SLEEP >> /tmp/lock-sleep-finder.nagiosrep
   echo "Soglia di allarme: "$PUNTEGGIO_ALLARME >> /tmp/lock-sleep-finder.nagiosrep 
   cp  /tmp/lock-sleep-finder.nagiosrep /nagios_reps/Sospetto_deadlock
else
   # Tolgo critical
   rm -f /nagios_reps/Sospetto_deadlock 2>/dev/null
fi

if [ $PUNTEGGIO_LOCK_SLEEP -gt 0 ] ; then
   echo $DATA $NUMERO_PROCESSI_IN_LOCK_SLEEP $PUNTEGGIO_LOCK_SLEEP $PUNTEGGIO_ALLARME | awk '{ printf "%-15s %6d %6d %6d\n",$1,$2,$3,$4; }' >> $UTILITY_DIR/out/lock-sleep-finder-log
fi

exit 0


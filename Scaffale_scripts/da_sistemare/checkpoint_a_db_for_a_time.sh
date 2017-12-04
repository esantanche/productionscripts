#!/bin/sh 
#

DURATA_MINUTI=180
#DURATA_MINUTI=5
INTERVALLO_TRA_CHECKPOINT_SECONDI=60

. /home/sybase/.profile

# E.Santanche 6.2.2004 script che esegue un checkpoint su tutti i db Sybase
# Va usato prima di effettuare uno shutdown 'forced' del server per evitare
# perdite di dati

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

NOMEDB=$1

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

TIMESTAMP_BEGIN=$(/usr/bin/date +%Y%m%d-%H%M)

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

rm -f $UTILITY_DIR/out/checkpoint_a_db_for_a_time

MAX_LOG_SIZE=0
echo $DURATA_MINUTI
countdown_secondi=`expr $DURATA_MINUTI \* 60`
echo countdown_secondi=$countdown_secondi
while [ $countdown_secondi -gt 0 ] 
do
   echo Secondi rimasti $countdown_secondi
   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF > /tmp/checkpoint_a_db_$$
use $NOMEDB
go
select 'LOGBYTES',4096*(reserved_pgs(id,doampg)+reserved_pgs(id,ioampg)) from sysindexes where id=8
go
checkpoint
go
quit
EOF
   LOG_BYTES=`grep LOGBYTES /tmp/checkpoint_a_db_$$ | awk '{ print $2; }'`
   TIMESTAMP_ATTUALE=$(/usr/bin/date +%Y%m%d-%H%M)
   echo $TIMESTAMP_ATTUALE $NOMEDB $LOG_BYTES | awk '{ printf "%-15s Il log del db %-16s occupa %6.1f MB\n", $1, $2, $3/1048576; }' >> $UTILITY_DIR/out/checkpoint_a_db_for_a_time
   if [ $MAX_LOG_SIZE -lt $LOG_BYTES ] ; then
      MAX_LOG_SIZE=$LOG_BYTES
   fi
   echo Prima dello sleep $INTERVALLO_TRA_CHECKPOINT_SECONDI
   sleep $INTERVALLO_TRA_CHECKPOINT_SECONDI
   countdown_secondi=`expr $countdown_secondi \- $INTERVALLO_TRA_CHECKPOINT_SECONDI`
   echo Termine sleep $countdown_secondi
done

DATA_ATTUALE=$(/usr/bin/date +%Y-%m-%d)
echo $DATA_ATTUALE $NOMEDB $MAX_LOG_SIZE | awk '{ printf "%-15s Il log del db %-16s ha occupato max %6.1f MB\n", $1, $2, $3/1048576; }' >> $UTILITY_DIR/out/checkpoint_a_db_for_a_time_max
TIMESTAMP_END=$(/usr/bin/date +%Y%m%d-%H%M)

echo "Subject: [CHKPT] Report checkpoint notturno su "$ASE_NAME" - db "$NOMEDB >  /tmp/checkpoint_a_db_$$.mail
echo "To: dba@kyneste.com"  >> /tmp/checkpoint_a_db_$$.mail
echo "Conclusione dello script di checkpoint una volta al minuto (o piu')." >> /tmp/checkpoint_a_db_$$.mail
echo "Nome del server Sybase sul quale e' stato fatto il checkpoint - " $ASE_NAME >> /tmp/checkpoint_a_db_$$.mail
echo "Nome della macchina che ospita il server Sybase - "`hostname` >> /tmp/checkpoint_a_db_$$.mail
echo "Nome del database sul quale e' stato fatto il checkpoint - " $NOMEDB >> /tmp/checkpoint_a_db_$$.mail
echo "Durata del periodo di svolgimento dei checkpoint - " $DURATA_MINUTI "min" >> /tmp/checkpoint_a_db_$$.mail
echo "Inizio del periodo di svolgimento dei checkpoint - " $TIMESTAMP_BEGIN >> /tmp/checkpoint_a_db_$$.mail
echo "Fine del periodo di svolgimento dei checkpoint - " $TIMESTAMP_END >> /tmp/checkpoint_a_db_$$.mail
echo "Intervallo tra due checkpoint - " $INTERVALLO_TRA_CHECKPOINT_SECONDI "sec" >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
NUMERO_RIGHE=`echo $DURATA_MINUTI $INTERVALLO_TRA_CHECKPOINT_SECONDI | awk '{ print "",int($1 * 60.0 / $2),"\n"; }'`
echo "Report delle 10 misurazioni piu' alte fatte questa notte." >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
cat $UTILITY_DIR/out/checkpoint_a_db_for_a_time | sort -k 8.1nr | head -10  >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
echo "Le 5 date in cui il massimo notturno e' stato piu' elevato" >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
cat $UTILITY_DIR/out/checkpoint_a_db_for_a_time_max | sort  -k 10.1nr | head -5 >> /tmp/checkpoint_a_db_$$.mail

/usr/sbin/sendmail -f loadmxok@kyneste.com dba@kyneste.com < /tmp/checkpoint_a_db_$$.mail

rm -f /tmp/checkpoint_a_db_$$.mail

rm -f /tmp/checkpoint_a_db_$$


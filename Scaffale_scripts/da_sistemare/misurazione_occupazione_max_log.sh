#!/bin/sh 
#

DURATA_MINUTI=1430
#DURATA_MINUTI=15
INTERVALLO_TRA_CHECKPOINT_SECONDI=275

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

DATA_BEGIN=$(/usr/bin/date +%Y%m%d-%H%M)
MIN_INIZIO=`expr $(/usr/bin/date +%H) \* 60 \+ $(/usr/bin/date +%M)`
MIN_ATTUALI=$MIN_INIZIO

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

MAX_LOG_SIZE=0
echo $DURATA_MINUTI
while [ `expr $MIN_ATTUALI \- $MIN_INIZIO` -lt $DURATA_MINUTI ] 
do
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
   DATA=$(/usr/bin/date +%Y%m%d-%H%M)
   #echo $DATA $NOMEDB $LOG_BYTES | awk '{ printf "%-15s Il log del db %-16s occupa %6.1f MB\n", $1, $2, $3/1048576; }' >> $UTILITY_DIR/out/checkpoint_a_db_for_a_time
   if [ $MAX_LOG_SIZE -lt $LOG_BYTES ] ; then
      MAX_LOG_SIZE=$LOG_BYTES
   fi
   sleep $INTERVALLO_TRA_CHECKPOINT_SECONDI
   MIN_ATTUALI=`expr $(/usr/bin/date +%H) \* 60 \+ $(/usr/bin/date +%M)`
done

DATA_END=$(/usr/bin/date +%Y%m%d-%H%M)
echo $DATA_END $NOMEDB $MAX_LOG_SIZE | awk '{ printf "%-15s Il log del db %-16s ha occupato max %6.1f MB\n", $1, $2, $3/1048576; }' >> $UTILITY_DIR/out/misurazione_occupazione_max_log

echo "Subject: [MAXLOG] Report occupazione max log su "$ASE_NAME" - db "$NOMEDB >  /tmp/checkpoint_a_db_$$.mail
echo "To: dba@kyneste.com"  >> /tmp/checkpoint_a_db_$$.mail
echo "Conclusione dello script di misurazione log." >> /tmp/checkpoint_a_db_$$.mail
echo "Nome del server Sybase sul quale e' stato fatta la misurazione - " $ASE_NAME >> /tmp/checkpoint_a_db_$$.mail
echo "Nome della macchina che ospita il server Sybase - "`hostname` >> /tmp/checkpoint_a_db_$$.mail
echo "Nome del database sul quale e' stata fatta la misurazione - " $NOMEDB >> /tmp/checkpoint_a_db_$$.mail
echo "Durata del periodo di misurazione - " $DURATA_MINUTI "min" >> /tmp/checkpoint_a_db_$$.mail
echo "Inizio del periodo di misurazione - " $DATA_BEGIN >> /tmp/checkpoint_a_db_$$.mail
echo "Fine del periodo di misurazione - " $DATA_END >> /tmp/checkpoint_a_db_$$.mail
echo "Intervallo tra due misure - " $INTERVALLO_TRA_CHECKPOINT_SECONDI "sec" >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
#echo "Report delle misurazioni effettuate." >> /tmp/checkpoint_a_db_$$.mail
#echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
#cat $UTILITY_DIR/out/checkpoint_a_db_for_a_time  >> /tmp/checkpoint_a_db_$$.mail
#echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
echo "Massima occupazione log negli ultimi 10 giorni." >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
tail -10 $UTILITY_DIR/out/misurazione_occupazione_max_log >> /tmp/checkpoint_a_db_$$.mail
echo "=================================================================" >> /tmp/checkpoint_a_db_$$.mail
echo "Massimo dei massimi - "`cat $UTILITY_DIR/out/misurazione_occupazione_max_log  | cut -d "x" -f 2 | sort -n | tail -1` >> /tmp/checkpoint_a_db_$$.mail

/usr/sbin/sendmail -f maxlog@kyneste.com dba@kyneste.com < /tmp/checkpoint_a_db_$$.mail

rm -f /tmp/checkpoint_a_db_$$.mail

rm -f /tmp/checkpoint_a_db_$$


#!/bin/sh 
#

# Stripe extra: ogni DIM_PER_STRIPE_EXTRA GB di grandezza di un db facciamo una stripe in piu'
DIM_PER_STRIPE_EXTRA=15

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

if [ $1'a' = 'a' -o $2'a' = 'a' -o $3'a' = 'a' ] ; then
   echo "Usage: dare come parametri il nome del db di cui eseguire il dump una tantum, "
   echo "la data del dump o comunque una stringa identificatrice del dump, la directory"
   echo "in cui mettere il dump"
   exit 0
fi

# Parametri da passare: nome del db, data aaaammgg, directory in cui mettere il dump
NOMEDB=$1
DATADUMP=$2
DUMP_DIR=$3

DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    
INIZIO_EPOCH=`epoch-it.pl`

# Calcolo la dimesione del database da dumpare perche' se e' piu'
# piccolo di 5 GB faccio due stripe invece di quelle standard
# indicate da NUM_STRIPE
DIMENSIONE_DB=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME <<EOF | grep DIMENSIONE | awk '{ print $2; }'
select 'DIMENSIONE',sum(size)/262144 from sysusages u, sysdatabases d where d.name='$NOMEDB' and d.dbid=u.dbid
go
quit
EOF`

#echo Dimensione db $DIMENSIONE_DB GB

NUM_STRIPE_EXTRA=`expr $DIMENSIONE_DB \/ $DIM_PER_STRIPE_EXTRA`

NUM_STRIPE_TOTALI=`expr $NUM_STRIPE_EXTRA \+ 2`

if [ $NUM_STRIPE_TOTALI -gt 9 ] ; then
   NUM_STRIPE_TOTALI=9
fi

# La data me la faccio passare come parametro perche' 
# voglio che sia sempre la stessa per tutti i dump

rm -f $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#?#.cmp.dmp* 2>/dev/null

PATH_SQL=/tmp/dumpmx_1shot_singolodb_striped.multistripe.sh#${NOMEDB}#sql

echo dump database $NOMEDB to > $PATH_SQL

N=0
STRIPON="            "
while [ $N -lt $NUM_STRIPE_TOTALI ] ; 
do
   N=`expr $N \+ 1`
   echo "$STRIPON \"compress::6::$DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#$N#.cmp.dmp"\" >> $PATH_SQL
   STRIPON="   stripe on"
done

echo go >> $PATH_SQL
echo quit >> $PATH_SQL

#cat $PATH_SQL

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  -i $PATH_SQL > /tmp/dumpmx_dump_output_$$

# Testare la presenza del 'DUMP is complete' nell'output 

DUMP_IS_COMPLETE=`grep "DUMP is complete" /tmp/dumpmx_dump_output_$$ | wc -l`
#echo $DUMP_IS_COMPLETE

if [ $DUMP_IS_COMPLETE -eq 1 ] ; then
   echo $(/usr/bin/date +%Y%m%d-%H:%M) $DATADUMP $NOMEDB Completo >> $DUMP_DIR/dmpmx1shot-$DATADUMP-$NOMEDB.ok
   ESITO='Ok'
   CODICE_RITORNO=0
else
   echo $(/usr/bin/date +%Y%m%d-%H:%M) $DATADUMP $NOMEDB Errore   >> $DUMP_DIR/dmpmx1shot-$DATADUMP-$NOMEDB.err
   ESITO='NON RIUSCITO!!!'
   CODICE_RITORNO=1
fi

FINE_ORE=$(/usr/bin/date +%H)       
FINE_MIN=$(/usr/bin/date +%M)   
FINE_EPOCH=`epoch-it.pl`

echo "Subject: [DUMP1SHOT] <"$ESITO"> Dump "$ASE_NAME" - "$NOMEDB" - "$DATADUMP >  /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "To: dba@kyneste.com"  >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Esito del dump " >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "==========================" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "$ESITO" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "    " >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo $DATA $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN | nawk '
                                    { inizio_ore=$2;
                                      inizio_min=$3;
                                      fine_ore=$4;
                                      fine_min=$5;
                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
                                      if (diff < 0) { diff += 1440; };
                                      print "Tempo impiegato";
                                      print "====================================";
                                      printf "Inizio ore %02d:%02d\n",inizio_ore,inizio_min;
                                      printf "Fine ore   %02d:%02d\n",fine_ore,fine_min;
                                      printf "Durata ore %02d:%02d\n",int(diff/60),diff % 60;
                                    }' >> /tmp/dump_1shot_singolo_$NOMEDB.mail 

#echo $DATA $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN $NOMEDB | nawk '
#                                    { inizio_ore=$2;
#                                      inizio_min=$3;
#                                      fine_ore=$4;
#                                      fine_min=$5;
#                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
#                                      if (diff < 0) { diff += 1440; };
#                                      printf "%-8s %-20s %02d:%02d->%02d:%02d(%02d:%02d)\n",$1,$6,
#                                                inizio_ore,inizio_min,fine_ore,fine_min,
#                                                int(diff/60),diff % 60; 
#                                    }' >> $UTILITY_DIR/out/log_operazioni_dump_intraday

echo "    " >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Server e db" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "==========================" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Nome del server Sybase sul quale e' stato fatto il dump     - " $ASE_NAME >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Nome della macchina che ospita il server Sybase             - " `hostname` >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Nome del database del quale e' stato fatto il dump          - " $NOMEDB >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "    " >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "File di dump" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "==========================" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Parte del nome dato al dump - "$DATADUMP >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Path completo del dump      - "$DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP"#n#.cmp.dmp" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Numero di stripe            - "$NUM_STRIPE_TOTALI >> /tmp/dump_1shot_singolo_$NOMEDB.mail
echo "Dettagli delle stripe del dump" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
if [ -s $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#1#.cmp.dmp ] ;  then
   ls -og $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#?#.cmp.dmp | cut -c 15-  >> /tmp/dump_1shot_singolo_$NOMEDB.mail
else
   echo Dump non esistente >> /tmp/dump_1shot_singolo_$NOMEDB.mail
fi
echo "    " >> /tmp/dump_1shot_singolo_$NOMEDB.mail

#/usr/sbin/sendmail -f dump1shot@kyneste.com dba@kyneste.com < /tmp/dump_1shot_singolo_$NOMEDB.mail

#sh $UTILITY_DIR/centro_log_operazioni.sh DUMP1SHOT $NOMEDB $CODICE_RITORNO $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN
sh $UTILITY_DIR/centro_unificato_messaggi.sh DUMP1SHOT $NOMEDB $CODICE_RITORNO $INIZIO_EPOCH $FINE_EPOCH /tmp/dump_1shot_singolo_$NOMEDB.mail 

rm -f /tmp/dump_1shot_singolo_$NOMEDB.mail
rm -f /tmp/dumpmx_dump_output_$$

if [ $CODICE_RITORNO -eq 0 ] ; then
   echo OK > /tmp/notifica_dumpmx.$$
else
   echo ERRORE > /tmp/notifica_dumpmx.$$
fi
echo HOSTNAME `hostname` >> /tmp/notifica_dumpmx.$$
echo DATABASE $NOMEDB >> /tmp/notifica_dumpmx.$$
echo NOMEPRIMASTRIPE dmpmx1shot-$NOMEDB-$DATADUMP#1#.cmp.dmp >> /tmp/notifica_dumpmx.$$
ls -1 $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#?#.cmp.dmp | nawk -v hostname=`hostname` '{ printf "STRIPE %s:%s\n",hostname,$0; }' >> /tmp/notifica_dumpmx.$$

#echo $NOMI_HOST_MACCHINE

for m in `echo $NOMI_HOST_MACCHINE | awk 'BEGIN { FS=","; }{ print $1,"\n",$2,"\n",$3,"\n",$4,"\n"; }'`
do
   #echo Notifica verso $m
   scp /tmp/notifica_dumpmx.$$ $m:/tmp/notifica_dumpmx#$(hostname)#${NOMEDB}
done

rm -f /tmp/notifica_dumpmx.$$
 
exit 0


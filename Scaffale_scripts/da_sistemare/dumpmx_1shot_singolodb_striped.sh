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

# La data me la faccio passare come parametro perche' 
# voglio che sia sempre la stessa per tutti i dump

rm -f $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#?#.cmp.dmp* 2>/dev/null

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dumpmx_dump_output_$$
dump database $NOMEDB to "compress::6::$DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#1#.cmp.dmp"
     stripe on "compress::6::$DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#2#.cmp.dmp"
     stripe on "compress::6::$DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#3#.cmp.dmp"
go
quit
EOF

# Testare la presenza del 'DUMP is complete' nell'output 

DUMP_IS_COMPLETE=`grep "DUMP is complete" /tmp/dumpmx_dump_output_$$ | wc -l`
#echo $DUMP_IS_COMPLETE

if [ $DUMP_IS_COMPLETE -eq 1 ] ; then
   echo $(/usr/bin/date +%Y%m%d-%H:%M) $DATADUMP $NOMEDB Completo >> $DUMP_DIR/dmpmx1shot-$DATADUMP.ok
   #echo NODELETE dmpmx1shot-$NOMEDB-$DATADUMP#1#.cmp.dmp >> $DUMP_DIR/dmpmx1shot-$DATADUMP.rep
   #echo NODELETE dmpmx1shot-$NOMEDB-$DATADUMP#2#.cmp.dmp >> $DUMP_DIR/dmpmx1shot-$DATADUMP.rep
   #echo NODELETE dmpmx1shot-$NOMEDB-$DATADUMP#3#.cmp.dmp >> $DUMP_DIR/dmpmx1shot-$DATADUMP.rep
   ESITO='Ok'
   CODICE_RITORNO=0
else
   echo $(/usr/bin/date +%Y%m%d-%H:%M) $DATADUMP $NOMEDB Errore   >> $DUMP_DIR/dmpmx1shot-$DATADUMP.err
   ESITO='NON RIUSCITO!!!'
   CODICE_RITORNO=1
fi

FINE_ORE=$(/usr/bin/date +%H)       
FINE_MIN=$(/usr/bin/date +%M)   


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

echo $DATA $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN $NOMEDB | nawk '
                                    { inizio_ore=$2;
                                      inizio_min=$3;
                                      fine_ore=$4;
                                      fine_min=$5;
                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
                                      if (diff < 0) { diff += 1440; };
                                      printf "%-8s %-20s %02d:%02d->%02d:%02d(%02d:%02d)\n",$1,$6,
                                                inizio_ore,inizio_min,fine_ore,fine_min,
                                                int(diff/60),diff % 60; 
                                    }' >> $UTILITY_DIR/out/log_operazioni_dump_intraday

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
echo "Dettagli delle stripe del dump" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
if [ -s $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#1#.cmp.dmp ] ;  then
   ls -og $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#?#.cmp.dmp | cut -c 15-  >> /tmp/dump_1shot_singolo_$NOMEDB.mail
else
   echo Dump non esistente >> /tmp/dump_1shot_singolo_$NOMEDB.mail
fi
echo "    " >> /tmp/dump_1shot_singolo_$NOMEDB.mail
#echo "Spiegazioni per csc" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
#echo "============================================" >> /tmp/dump_1shot_singolo_$NOMEDB.mail
#cat $UTILITY_DIR/dump_1shot_singolo_spiegazioni_per_csc >> /tmp/dump_1shot_singolo_$NOMEDB.mail

/usr/sbin/sendmail -f dump1shot@kyneste.com dba@kyneste.com < /tmp/dump_1shot_singolo_$NOMEDB.mail

sh $UTILITY_DIR/centro_log_operazioni.sh DUMP1SHOT $NOMEDB $CODICE_RITORNO $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN

rm -f /tmp/dump_1shot_singolo_$NOMEDB.mail
rm -f /tmp/dumpmx_dump_output_$$

if [ -s $UTILITY_DIR/dumpmx_1shot_singolodb_parametri ] ; then
   #echo Ho trovato parametri da valutare
   #echo dumpmx_1shot_singolodb.sh
   if [ $CODICE_RITORNO -eq 0 ] ; then
      echo OK > /tmp/notifica_dumpmx_1shot_singolodb
   else
      echo ERRORE > /tmp/notifica_dumpmx_1shot_singolodb
   fi
   echo DATABASE $NOMEDB >> /tmp/notifica_dumpmx_1shot_singolodb
   echo NOMEPRIMASTRIPE dmpmx1shot-$NOMEDB-$DATADUMP#1#.cmp.dmp >> /tmp/notifica_dumpmx_1shot_singolodb
   ls -1 $DUMP_DIR/dmpmx1shot-$NOMEDB-$DATADUMP#?#.cmp.dmp | nawk -v hostname=`hostname` '{ printf "STRIPE %s:%s\n",hostname,$0; }' >> /tmp/notifica_dumpmx_1shot_singolodb 
   NOTIFICA_MACCHINE=`grep NOTIFICA_MACCHINE= $UTILITY_DIR/dumpmx_1shot_singolodb_parametri | cut -f 2 -d =`
   for m in `grep NOTIFICA $UTILITY_DIR/dumpmx_1shot_singolodb_parametri | awk '{ print $2; }'`
   do
      #echo $m
      scp /tmp/notifica_dumpmx_1shot_singolodb $m:/tmp 
   done 
fi

exit 0


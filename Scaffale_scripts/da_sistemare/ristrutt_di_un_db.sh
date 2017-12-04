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

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri il nome del db da ristrutturare e il path per i dump"
   exit 1
fi

NOMEDB=$1
PATHDUMP=$2

DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    

CODICE_RISTR="RST"$(/usr/bin/date +%m%d)
REP=${UTILITY_DIR}/out/ristrutt_di_un_db_${NOMEDB}

# Ristrutturazione di un db
# dump del vecchio db
# load nel nuovo
# fix del nuovo
# dbcc del nuovo

echo Ristrutturazione NOMEDB=$NOMEDB PATHDUMP=$PATHDUMP CODICE_RISTR=$CODICE_RISTR > $REP

sh $UTILITY_DIR/kill_sessions.sh $NOMEDB     >> $REP
sh $UTILITY_DIR/kill_sessions.sh $NOMEDB@NEW >> $REP

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF >> $REP
sp_dboption $NOMEDB, single, true
go
sp_dboption $NOMEDB@NEW, single, true
go
use $NOMEDB
go
checkpoint
go
use $NOMEDB@NEW
go
checkpoint
go
quit
EOF

sh $UTILITY_DIR/fixsegmap_singolodb_tutti_misti.sh $NOMEDB >> $REP

echo Avvio il dump di $NOMEDB $CODICE_RISTR $PATHDUMP  >> $REP
sh $UTILITY_DIR/dumpmx_1shot_singolodb_striped.multistripe.sh $NOMEDB $CODICE_RISTR $PATHDUMP >> $REP

echo Avvio il load su $NOMEDB@NEW >> $REP 
sh $UTILITY_DIR/loadmx_cron.sh $NOMEDB@NEW $PATHDUMP/dmpmx1shot-$NOMEDB-$CODICE_RISTR#1#.cmp.dmp NOBCP >> $REP

sh $UTILITY_DIR/fixsegmap_singolodb.sh $NOMEDB@NEW >> $REP

#echo "QUESTO PASSAGGIO NON CI DEVE ESSERE ALTRIMENTI" >> $REP
#echo "LA RISTRUTTURAZIONE *NON* E' VALIDA"  >> $REP
#echo "(il db non deve tornare in multiuser mode prima" >> $REP
#echo "del rename)" >> $REP

#isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF   >> $REP
#sp_dboption $NOMEDB, single, false
#go
#sp_dboption $NOMEDB@NEW, single, false
#go
#use $NOMEDB
#go
#checkpoint
#go
#use $NOMEDB@NEW
#go
#checkpoint
#go
#quit
#EOF

FINE_ORE=$(/usr/bin/date +%H)       
FINE_MIN=$(/usr/bin/date +%M)   

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
                                    }'   >> $REP

cat $REP

echo "ORA MANUALMENTE:"
echo " "
echo "1) Fare il rename"
echo "use "$NOMEDB
echo "sp_renamedb "$NOMEDB", "$NOMEDB"@OLD"
echo "use "$NOMEDB"@NEW"
echo "sp_renamedb "$NOMEDB"@NEW, "$NOMEDB
echo " "
echo "2) Togliere il single user mode"
echo "use master"
echo "sp_dboption "$NOMEDB", single, false"
echo "use "$NOMEDB
echo "checkpoint"
echo " "
echo "3) Controllare i dbo"
echo "Nel caso per cambiare dbo:"
echo "use <db>"
echo "sp_changedbowner <loginame>"
echo " "
echo "4) Impostare o controllare le dboptions"
echo " "
echo "5) eventualmente fare il dbcc (solo db piccoli)"
echo "sh $UTILITY_DIR/dbccmx_singolodb.sh ${NOMEDB}"
echo " "
echo "6) Verificare sysusers e sysalternates"
echo "7) Controllare che il dbid sia rimasto possibilmente"
echo "   quello di prima"
echo "8) Controllare che i device non siano"
echo "   impostati come di default per la creazione di db"
echo "9) Riconfigurare il dbccdb e pulire le tracce del vecchio"
echo "   db un tutte le tabelle"

exit 0;


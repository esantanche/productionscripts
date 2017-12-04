#!/bin/sh 
#

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

#NUM_GIORNI=3 # Numero di giorni di dump da tenere in linea
#DUMP_DIR=/sybased1/dump

# Parametri da passare: nome del db e data aaaammgg
NOMEDB=$1
DATADUMP=$2

# La data me la faccio passare come parametro perche' 
# voglio che sia sempre la stessa per tutti i dump
#echo $DATADUMP

# ?????????????? TBD testare con la shell con cui lo invochera'
# il backup_tsm_pre.sh

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

#date > /tmp/date-dump.log

#DATA=$(/usr/bin/date +%Y%m%d)

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

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

# Recupero parametri
NUM_GIORNI=`grep NUMERO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`

#echo $NUM_GIORNI

# Cancellazione del dump piu' vecchio del db in esame
NUMERO_DUMP_PRESENTI=`ls -1tr $PATH_DUMP_DIR/dmpmx-$NOMEDB-*.cmp.dmp 2>/dev/null | wc -l`

#echo $NUMERO_DUMP_PRESENTI

if [ $NUMERO_DUMP_PRESENTI -ge NUM_GIORNI ] ; then
   echo Devo cancellare il piu vecchio
   PATH_PIU_VECCHIO=`ls -1tr $PATH_DUMP_DIR/dmpmx-$NOMEDB-*.cmp.dmp | head -1`
   echo $PATH_PIU_VECCHIO
   rm -f $PATH_PIU_VECCHIO
fi

# Lo ripeto ancora nel caso che fosse rimasto un altro vecchio dump
# ovvero che fossero due i dump vecchi da eliminare
# Serve per es. se voglio ridurre di uno il numero di dump da tenere
# e quindi lo script si trova con due invece che un dump di troppo
# da togliere
NUMERO_DUMP_PRESENTI=`ls -1tr $PATH_DUMP_DIR/dmpmx-$NOMEDB-*.cmp.dmp 2>/dev/null | wc -l`

#echo $NUMERO_DUMP_PRESENTI

if [ $NUMERO_DUMP_PRESENTI -ge NUM_GIORNI ] ; then
   #echo Devo cancellare il piu vecchio
   PATH_PIU_VECCHIO=`ls -1tr $PATH_DUMP_DIR/dmpmx-$NOMEDB-*.cmp.dmp | head -1`
   #echo $PATH_PIU_VECCHIO
   rm -f $PATH_PIU_VECCHIO
fi

rm -f $PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP.cmp.dmp* 2>/dev/null


isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/dumpmx_dump_output
use $NOMEDB
go
checkpoint
go
use master
go
dump transaction $NOMEDB with truncate_only
go
use $NOMEDB
go
checkpoint
go
use master
go
dump database $NOMEDB to "compress::6::$PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP.cmp.dmp"
go
use $NOMEDB
go
checkpoint
go
use master
go
dump transaction $NOMEDB with truncate_only
go
quit
EOF

# Testare la presenza del 'DUMP is complete' nell'output 

DUMP_IS_COMPLETE=`grep "DUMP is complete" /tmp/dumpmx_dump_output | wc -l`
#echo $DUMP_IS_COMPLETE

if [ $DUMP_IS_COMPLETE -eq 1 ] ; then
   echo $DATADUMP $NOMEDB Completo >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
   echo NODELETE dmpmx-$NOMEDB-$DATADUMP.cmp.dmp >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
else
   echo $DATADUMP $NOMEDB Errore   >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
fi

exit 0;




#!/bin/sh 
#

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Questo script fa il dump di un singolo db dividendolo su due stripe

# Parametri da passare: nome del db e data aaaammgg
NOMEDB=$1
DATADUMP=$2

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

# Recupero parametri
NUM_GIORNI=`grep NUMERO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`

# Cancellazione del dump piu' vecchio del db in esame
# L'elenco dei dump presenti deve essere corretto per tenere presenti le stripe
# Vengono cancellati tutti i dump piu vecchi in modo da avere solo
# un numero di dump pari a $NUM_GIORNI

NUMERO_DUMP_PRESENTI=`ls -1 $PATH_DUMP_DIR/dmpmx-${NOMEDB}*.cmp.dmp | cut -d "-" -f 3 | cut -c -8 | uniq | wc -l`

while [ $NUMERO_DUMP_PRESENTI -ge $NUM_GIORNI ] ; do
   #echo Devo cancellare il dump piu vecchio
   DATA_PIU_VECCHIA=`ls -1 $PATH_DUMP_DIR/dmpmx-${NOMEDB}*.cmp.dmp | cut -d "-" -f 3 | cut -c -8 | uniq | head -1`
   #echo Ovvero quello del $DATA_PIU_VECCHIA
   rm -f $PATH_DUMP_DIR/dmpmx-$NOMEDB-${DATA_PIU_VECCHIA}*.cmp.dmp
   NUMERO_DUMP_PRESENTI=`ls -1 $PATH_DUMP_DIR/dmpmx-${NOMEDB}*.cmp.dmp 2>/dev/null | cut -d "-" -f 3 | cut -c -8 | uniq | wc -l`
done

# Cancello il dump della data odierna nel caso fosse gia' presente nella
# directory dei dump
rm -f $PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP*.cmp.dmp 2>/dev/null

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
dump database $NOMEDB to "compress::6::$PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP#1#.cmp.dmp"
     stripe on "compress::6::$PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP#2#.cmp.dmp"
     stripe on "compress::6::$PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP#3#.cmp.dmp"
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
   echo NODELETE dmpmx-$NOMEDB-$DATADUMP#1#.cmp.dmp >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
   echo NODELETE dmpmx-$NOMEDB-$DATADUMP#2#.cmp.dmp >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
   echo NODELETE dmpmx-$NOMEDB-$DATADUMP#3#.cmp.dmp >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
else
   echo $DATADUMP $NOMEDB Errore   >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
fi

exit 0;


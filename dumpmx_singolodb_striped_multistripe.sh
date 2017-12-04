#!/bin/sh 
#

# Questo script richiede come parametri il nome del db e la data in formato aaaammgg e non
# fa controlli per cui il nome del db in particolare deve essere corretto 

# Stripe extra: ogni DIM_PER_STRIPE_EXTRA GB di grandezza di un db facciamo una stripe in piu'
DIM_PER_STRIPE_EXTRA=15 

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Questo script fa il dump di un singolo db dividendolo in stripe

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

NUMERO_DUMP_PRESENTI=`ls -1 $PATH_DUMP_DIR/dmpmx-${NOMEDB}*.cmp.dmp 2>/dev/null | cut -d "-" -f 3 | cut -c -8 | uniq | wc -l`

#echo num dump pres $NUMERO_DUMP_PRESENTI

#echo tolgo il while da rimettere
while [ $NUMERO_DUMP_PRESENTI -ge $NUM_GIORNI ] ; do
   #echo Devo cancellare il dump piu vecchio
   DATA_PIU_VECCHIA=`ls -1 $PATH_DUMP_DIR/dmpmx-${NOMEDB}*.cmp.dmp 2>/dev/null | cut -d "-" -f 3 | cut -c -8 | uniq | head -1`
   #echo Ovvero quello del $DATA_PIU_VECCHIA
   #echo tolgo la cancellazione del piu vecchio
   rm -f $PATH_DUMP_DIR/dmpmx-$NOMEDB-${DATA_PIU_VECCHIA}*.cmp.dmp
   NUMERO_DUMP_PRESENTI=`ls -1 $PATH_DUMP_DIR/dmpmx-${NOMEDB}*.cmp.dmp 2>/dev/null | cut -d "-" -f 3 | cut -c -8 | uniq | wc -l`
done

# Cancello il dump della data odierna nel caso fosse gia' presente nella
# directory dei dump
# echo tolgo rm dump stessa data
rm -f $PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP*.cmp.dmp 2>/dev/null

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

#echo Db $NOMEDB dimensione $DIMENSIONE_DB numero stripe totali $NUM_STRIPE_TOTALI

Create_sql_script()
{
cat  <<EOF
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
EOF

echo dump database $NOMEDB to  

N=0
STRIPON="            "
while [ $N -lt $NUM_STRIPE_TOTALI ] ;
do
   N=`expr $N \+ 1`
   echo "$STRIPON \"compress::6::$PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP#$N#.cmp.dmp\""  
   STRIPON="   stripe on"
done

cat  <<EOF
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
}

#echo Eseguo dump =============================================

#echo INIZIO

DUMP_IS_COMPLETE=0
`echo Create_sql_script` | isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 | grep -q "DUMP is complete" && DUMP_IS_COMPLETE=1 

#echo cod ret $? rets $DUMP_IS_COMPLETE

#echo dump is complete $DUMP_IS_COMPLETE

# echo Dump is complete $DUMP_IS_COMPLETE

if [ $DUMP_IS_COMPLETE -eq 1 ] ; then
   echo $DATADUMP $NOMEDB Completo >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
   N=0
   while [ $N -lt $NUM_STRIPE_TOTALI ] ;
   do
      N=`expr $N \+ 1`
      echo "NODELETE dmpmx-$NOMEDB-$DATADUMP#$N#.cmp.dmp"  >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
   done
   CODRET=0
else
   echo $DATADUMP $NOMEDB Errore   >> $PATH_DUMP_DIR/dmpmx-$DATADUMP.rep
   CODRET=1
fi

exit $CODRET;


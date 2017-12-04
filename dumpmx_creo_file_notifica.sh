#!/bin/sh 
#

# Questo script richiede come parametri il nome del db e la data in formato aaaammgg e non
# fa controlli per cui il nome del db in particolare deve essere corretto 

# Stripe extra: ogni DIM_PER_STRIPE_EXTRA GB di grandezza di un db facciamo una stripe in piu'
#DIM_PER_STRIPE_EXTRA=15 

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Questo script fa il dump di un singolo db dividendolo in stripe

if [ $1a = a ] ; then
   echo "Usage: dare come parametri il nome del db per cui creare il file di notifica"
   echo "da mandare alle altre macchine per comunicare la presenza del dump,"
   echo "eseguito dallo script notturno"
   exit 0
fi

# Parametri da passare: nome del db e data aaaammgg
NOMEDB=$1
#DATADUMP=$2

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

# devo vedere se il dump e' andato bene
#$UTILITY_DIR/out/esito_ultimo_dumpmx_alldb 
ESITO_DUMP_OK=`grep ok $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb | wc -l`

if [ $ESITO_DUMP_OK -eq 0 ] ; then
   echo Il dump notturno su $(hostname) non e"'" riuscito
   echo mettere una segnalazione di errore TBW
   exit 1
fi

# poi creo il file di notifica

DATADUMP=`cat $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb | awk '{ print $3; }'`

echo OK > /tmp/notifica_dumpmx.$$
echo HOSTNAME `hostname` >> /tmp/notifica_dumpmx.$$
echo DATABASE $NOMEDB >> /tmp/notifica_dumpmx.$$
echo NOMEPRIMASTRIPE dmpmx-$NOMEDB-$DATADUMP#1#.cmp.dmp >> /tmp/notifica_dumpmx.$$
ls -1 $PATH_DUMP_DIR/dmpmx-$NOMEDB-$DATADUMP#?#.cmp.dmp | nawk -v hostname=`hostname` '{ printf "STRIPE %s:%s\n",hostname,$0; }' >> /tmp/notifica_dumpmx.$$

#echo $NOMI_HOST_MACCHINE


# poi lo mando su tutte le macchine


for m in `echo $NOMI_HOST_MACCHINE | awk 'BEGIN { FS=","; }{ print $1,"\n",$2,"\n",$3,"\n",$4,"\n"; }'`
do
   #echo Notifica verso $m
   scp /tmp/notifica_dumpmx.$$ $m:/tmp/notifica_dumpmx#$(hostname)#${NOMEDB}
done

rm -f /tmp/notifica_dumpmx.$$

exit


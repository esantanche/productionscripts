#!/bin/sh 
#

#NUM_GIORNI=3 # Numero di giorni di dump da tenere in linea

# Parametri da passare: nome del db e data aaaammgg
NOMEDB=$1
#DATADUMP=$2

# La data me la faccio passare come parametro perche' 
# voglio che sia sempre la stessa per tutti i dump
#echo $DATADUMP

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

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

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
#export SUNDAYDIR=/sybased2/sunday_dir


if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

# Recupero parametri
# servono ?????
#NUM_GIORNI=`grep NUMERO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`

#echo $NUM_GIORNI

rm -f $UTILITY_DIR/out/esito_bcp_output_ultimo_bcp

#NUMTAB=0 # ????????? TBD da togliere
ERRORI_PRESENTI=0
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------|sysgams' 
set nocount on
go
use $NOMEDB
go
select  '$NOMEDB.' + u.name +  '.'  + o.name from sysobjects o, sysusers u where u.uid=o.uid and o.type in ('S','U','V') order by u.name,o.name
go
quit
EOF`
do
   echo $(/usr/bin/date +%Y%m%d-%H%M%S) BCP di $i db $NOMEDB >>$UTILITY_DIR/out/esito_bcp_output_ultimo_bcp 
   bcp $i out $SUNDAYDIR/bcp-$i.bcp -e $SUNDAYDIR/bcp-$i.err -c -b 10 -T 1320000 -P $SAPWD -S $ASE_NAME -U $SAUSER 2>&1 >>$UTILITY_DIR/out/esito_bcp_output_ultimo_bcp
   ERROREBCP=$?
   if [ $ERROREBCP -gt 0 ] ; then
      ERRORI_PRESENTI=1
      break
   fi
   PRESENTE_FILE_ERRORE=`find $SUNDAYDIR | grep bcp.*err | wc -l`
   if [ $PRESENTE_FILE_ERRORE -gt 0 ] ; then
      ERRORI_PRESENTI=1
      break
   fi
   gzip -1 $SUNDAYDIR/*.bcp
   #NUMTAB=`expr $NUMTAB + 1`          # ????????????????????????????? TBD togliere
   #if [ $NUMTAB -gt 100 ] ; then      # ????????????????????????????? TBD togliere
   #   break                           # ????????????????????????????? TBD togliere
   #fi                                 # ????????????????????????????? TBD togliere
done

if [ $ERRORI_PRESENTI -eq 1 ] ; then
   # Ho un errore
   echo $DATA Errore bcp db $NOMEDB >> $UTILITY_DIR/out/esito_bcp
   echo Errore bcp: $ERROREBCP >> $UTILITY_DIR/out/esito_bcp
   echo Presenza file di errore: $PRESENTE_FILE_ERRORE >> $UTILITY_DIR/out/esito_bcp
   exit 1  
else
   # poi devo fare il tar di tutto
   find $SUNDAYDIR | grep .bcp.gz > $SUNDAYDIR/lista_files_$NOMEDB
   tar -cvf $SUNDAYDIR/bcp-$NOMEDB.tar -L $SUNDAYDIR/lista_files_$NOMEDB 1>/dev/null
   # poi devo cancellare tutti i bcp
   for j in `cat $SUNDAYDIR/lista_files_$NOMEDB`
   do
      rm -f $j
   done 
fi

echo $DATA Eseguito bcp db $NOMEDB >> $UTILITY_DIR/out/esito_bcp

exit 0;


#!/bin/sh 
#

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

DIR_IN_CUI_METTERE_DUMP_COPIATI=$PATH_TRASF_DIR

function prendi_un_dump {
   #echo Entro nella funzione prendi_un_dump

   # NOME_DUMP_DA_PRENDERE contiene il nome del dump da prendere ovvero il nome del db

   # fare scp del dump
   # vedere se le dimensioni sono uguali 

   # Cancello dump precedenti
   rm -f $DIR_IN_CUI_METTERE_DUMP_COPIATI/dmpmx*-${NOME_DUMP_DA_PRENDERE}-*
   rm -f $DIR_IN_CUI_METTERE_DUMP_COPIATI/nome_dump_$NOME_DUMP_DA_PRENDERE

   #echo Eseguo scp di $ULTIMO_DUMP
   scp mx2-prod-pridb:$PATH_DUMP_DIR/dmpmx*-${NOME_DUMP_DA_PRENDERE}-*${DATA_ULTIMO_DUMP}* $DIR_IN_CUI_METTERE_DUMP_COPIATI
   ERRORE_SCP_DUMP=$?
   #echo Finito scp codice ritorno $?
   if [ $ERRORE_SCP_DUMP -eq 0 ] ; then
      ls -1 $DIR_IN_CUI_METTERE_DUMP_COPIATI/dmpmx*-${NOME_DUMP_DA_PRENDERE}-*${DATA_ULTIMO_DUMP}* | head -1 > $DIR_IN_CUI_METTERE_DUMP_COPIATI/nome_dump_$NOME_DUMP_DA_PRENDERE
      #else
      #echo Errore nella scp di ${NOME_DUMP_DA_PRENDERE}
   fi
}

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    
INIZIO_EPOCH=`epoch-it.pl`

# prendo da pridb l'esito del suo dump
# prendo i vari dump

COPIA_DUMP_NON_RIUSCITI=0

#if [ -s /sybase/utility/out/esito_positivo_scp_da_pridb ] ; then
#   echo scp gia fatto con esito positivo
#   exit 0
#fi

#echo " "
#echo ESECUZIONE script prendo_dump_da_pridb.sh
#echo $(/usr/bin/date +%Y-%m-%d_%H:%M:%S)

rm -f /tmp/prendo_dump.esito_da_pridb
scp mx2-prod-pridb:$UTILITY_DIR/out/esito_ultimo_dumpmx_alldb /tmp/prendo_dump.esito_da_pridb
if [ ! -s /tmp/prendo_dump.esito_da_pridb ] ; then
   DUMP_RIUSCITI_SU_PRIDB=0
else
   DUMP_RIUSCITI_SU_PRIDB=`grep ok /tmp/prendo_dump.esito_da_pridb | wc -l`
   DATA_ULTIMO_DUMP=`cat /tmp/prendo_dump.esito_da_pridb | awk '{ print $3; }'`
fi
#echo DUMP_RIUSCITI_SU_PRIDB=$DUMP_RIUSCITI_SU_PRIDB

#echo prendo_dump_da_pridb.sh DATA_ULTIMO_DUMP=$DATA_ULTIMO_DUMP

REPORT_FILE=/tmp/.oggi/scp_da_pridb
rm -f $REPORT_FILE 

if [ $DUMP_RIUSCITI_SU_PRIDB -eq 1 ] ; then
   ITER=0
   COPIA_DUMP_NON_RIUSCITI=1
   while [ $ITER -lt 5 -a $COPIA_DUMP_NON_RIUSCITI -gt 0 ] ; do
      COPIA_DUMP_NON_RIUSCITI=0 
      # prendo CAP_MLCPROD
      NOME_DUMP_DA_PRENDERE=CAP_MLCPROD 
      #echo cerco di copiare $NOME_DUMP_DA_PRENDERE
      prendi_un_dump
      if [ $ERRORE_SCP_DUMP -gt 0 ] ; then
         COPIA_DUMP_NON_RIUSCITI=1
         echo ERRORE scp non riuscito $NOME_DUMP_DA_PRENDERE >> $REPORT_FILE 
      else
         echo scp riuscito $NOME_DUMP_DA_PRENDERE >> $REPORT_FILE 
      fi
      NOME_DUMP_DA_PRENDERE=CAP_MXPROD
      #echo cerco di copiare $NOME_DUMP_DA_PRENDERE
      prendi_un_dump
      if [ $ERRORE_SCP_DUMP -gt 0 ] ; then
         COPIA_DUMP_NON_RIUSCITI=1
         echo ERRORE scp non riuscito $NOME_DUMP_DA_PRENDERE >> $REPORT_FILE
      else
         echo scp riuscito $NOME_DUMP_DA_PRENDERE >> $REPORT_FILE 
      fi
      ITER=`expr $ITER \+ 1`
      #echo iter $ITER
      #echo COPIA_DUMP_NON_RIUSCITI=$COPIA_DUMP_NON_RIUSCITI 
      sleep 120
   done
else
   COPIA_DUMP_NON_RIUSCITI=1
   echo ERRORE Dump non riusciti su pridb >> $REPORT_FILE
fi

if [ $COPIA_DUMP_NON_RIUSCITI -eq 0 ] ; then
   echo `date` > /sybase/utility/out/esito_positivo_scp_da_pridb
fi

#echo COPIA_DUMP_NON_RIUSCITI=$COPIA_DUMP_NON_RIUSCITI

FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_EPOCH=`epoch-it.pl`

#sh $UTILITY_DIR/centro_log_operazioni.sh SCP ALL $COPIA_DUMP_NON_RIUSCITI $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN
sh $UTILITY_DIR/centro_unificato_messaggi.sh SCP ALL $COPIA_DUMP_NON_RIUSCITI $INIZIO_EPOCH $FINE_EPOCH $REPORT_FILE

#echo "   "

exit 0


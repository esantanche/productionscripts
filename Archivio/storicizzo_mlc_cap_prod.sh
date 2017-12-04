#!/bin/sh

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME
# pridb only
#export PATH_STORICO_MLC_CAP_PROD=/syb_bkp_mese/storico_MLC_CAP_PROD

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

# vedere se la copia e' ok
#   se è ok mettere la conferma in un file se no, mettere un NOK
# se è domenica fare il tar


cd ${PATH_STORICO_MLC_CAP_PROD}
if [ $? -gt 0 ] ; then
   echo ATTENZIONE ATTENZIONE ERRORE ERRORE
   echo script storicizzo_mlc_cap_prod.sh
   echo non riesco ad entrare nella directory
   echo ${PATH_STORICO_MLC_CAP_PROD}
   echo correggere subito la situazione e controllare
   echo i dump di MLC_CAP_PROD
   exit 1
fi

# Qui inserisco nel file distinta_dump_MLC_CAP_PROD una riga
# in formato data OK relativamente all'ultimo dump trovato
ULTIMO_DUMP=`ls -1tr dmpmx-MLC_CAP_PRO* | tail -1`
DATA_ULTIMO_DUMP=`echo $ULTIMO_DUMP | cut -d "-" -f 3 | cut -d "." -f 1`
if [ `grep $DATA_ULTIMO_DUMP distinta_dump_MLC_CAP_PROD | grep MANCANTE | wc -l` -gt 0 ] ; then
   cat distinta_dump_MLC_CAP_PROD | grep -v "$DATA_ULTIMO_DUMP.*MANCANTE" > distinta_dump_MLC_CAP_PROD.new
   rm distinta_dump_MLC_CAP_PROD
   mv distinta_dump_MLC_CAP_PROD.new distinta_dump_MLC_CAP_PROD 
   echo $DATA_ULTIMO_DUMP OK >> distinta_dump_MLC_CAP_PROD
fi

# controllo che le copie dei dump ci siano tutte 
# ovvero non devo trovare righe con la data seguita dalla
# stringa MANCANTE
NUMERO_COPIE_MANCANTI=`grep MANCANTE distinta_dump_MLC_CAP_PROD | wc -l`

if [ $NUMERO_COPIE_MANCANTI -gt 0 ] ; then
   echo ATTENZIONE ERRORE MANCANO DEI DUMP DI MLC_CAP_PROD
   echo Vedi script storicizzo_mlc_cap_prod.sh
   echo "============================================="
   cat distinta_dump_MLC_CAP_PROD
fi

# genero la riga relativa al dump che andrà copiato al prossimo dump
# questa riga verrà sostituita da una riga con la stessa data ma con la
# stringa OK invece della stringa MANCANTE, quando verrà eseguito il
# dump relativo
DATA=$(/usr/bin/date +%Y%m%d)
echo $DATA MANCANTE >> distinta_dump_MLC_CAP_PROD

if [ `date +%w` -eq 0 -a $NUMERO_COPIE_MANCANTI -eq 0 ] ; then
   # è domenica procedo a fare il tar

   NUMERO_DUMP_MLC_CAP_PROD=`ls -1 *.dmp | wc -l`

   if [ $NUMERO_DUMP_MLC_CAP_PROD -gt 3 ] ; then
      # cancellami DATA=$(/usr/bin/date +%Y%m%d)
      tar -cvf storico_MLC_CAP_PROD_$DATA.tar *.dmp
      if [ $? -eq 0 ] ; then
         gzip -9 *.tar
         rm -f *.dmp
      fi
   fi

fi

exit


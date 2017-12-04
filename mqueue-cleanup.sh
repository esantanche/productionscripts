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

if [ $USER != root ] ; then
   echo Eseguire come root
   exit 1
fi

LIMITE_IN_ORE=5

LIMITE_IN_SEC=`expr $LIMITE_IN_ORE \* 3600`

cd /var/spool/mqueue

ORA_ATTUALE=`epoch-it.pl`
ORA_LIMITE=`expr $ORA_ATTUALE \- $LIMITE_IN_SEC`

#echo ORA_ATTUALE=$ORA_ATTUALE
#echo ORA_LIMITE=$ORA_LIMITE

if [ `find . -name "qf*" | wc -l` -eq 0 ] ; then 
   exit
fi

rm -f /tmp/.oggi/mqueue_lista_files_da_cancellare
for file in `ls -1 qf*`
do
   #echo $file
   ORA_INVIO=`grep "^T" $file | cut -c 2-`
   if [ $ORA_INVIO -lt $ORA_LIMITE ] ; then
      #echo da cancellare $file
      NOME_TRONCATO=`echo $file | cut -c 2-`
      #echo NOME_TRONCATO=$NOME_TRONCATO
      #echo "?$NOME_TRONCATO" ==============================
      ls -1 ?$NOME_TRONCATO | awk '{ print "rm ",$1; }' >> /tmp/.oggi/mqueue_lista_files_da_cancellare
      #echo ====================
   fi 
done

if [ -s /tmp/.oggi/mqueue_lista_files_da_cancellare ] ; then

   NUM_MSG_DA_CANC=`wc -l /tmp/.oggi/mqueue_lista_files_da_cancellare`
   cat /tmp/.oggi/mqueue_lista_files_da_cancellare | sh
   DATAORA=$(date +%Y.%m.%d-%H:%M)
   echo $DATAORA $NUM_MSG_DA_CANC | awk '{ printf "%-20s Cancellati %4d messaggi\n",$1,$2; }' >> /tmp/.oggi/Log_cancellazione_mqueue
   echo "Cancellati "$NUM_MSG_DA_CANC" messaggi e-mail il cui invio non e' riuscito" > /inbacheca/Cancellazione_mail_$DATAORA 
   echo "nelle ultime "$LIMITE_IN_ORE" ore" >> /inbacheca/Cancellazione_mail_$DATAORA
fi

exit



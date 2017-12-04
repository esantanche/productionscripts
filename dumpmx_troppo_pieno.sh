#!/bin/sh 

SOGLIA_SPAZIO_LIBERO_MB=2000

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

Per_la_bacheca () {
   echo Numero giorni in linea di dump ridotto a $NUM_GIORNI 
   if [ $NUM_GIORNI -lt $NUM_MINIMO_GIORNI ] ; then
      echo "    "
      echo "Dal momento che il numero di giorni in linea e' adesso inferiore a"
      echo "quello minimo raccomandato, occorre provvedere all'ampliamento"
      echo "del file system "$PATH_DUMP_FS" sia pur senza particolare urgenza"
   fi
}

Per_nagios_espandere_subito () {
   echo "ATTENZIONE! Si e' ridotto lo spazio libero su "$PATH_DUMP_FS" e non e' possibile"
   echo "ridurre il numero di giorni in linea che e' gia' pari a 1."
   echo "Espandere subito il file system."
}

Check_settimanale () {
   echo "Il numero di giorni in linea di dump e' inferiore a quello minimo"
   echo "raccomandato."
   echo "Numero di giorni in linea:        "$NUM_GIORNI
   echo "Numero minimo di giorni in linea: "$NUM_MINIMO_GIORNI 
}

#echo $PATH_DUMP_FS

SPAZIO_LIBERO_FS_DUMP=`df -k $PATH_DUMP_FS | grep -v Filesystem | awk '{ print int($3 / 1000); }'`

#echo $SPAZIO_LIBERO_FS_DUMP

if [ $SPAZIO_LIBERO_FS_DUMP -lt $SOGLIA_SPAZIO_LIBERO_MB ] ; then
   # Riduco di uno il numero di giorni in linea
   NUM_GIORNI=`grep NUMERO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
   NUM_MINIMO_GIORNI=`grep NUMERO_MINIMO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
     
   rm -f /tmp/.oggi/dumpmx_troppo_pieno_msg        
   if [ $NUM_GIORNI -eq 1 ] ; then
      Per_nagios_espandere_subito > /tmp/.oggi/dumpmx_troppo_pieno_msg 
      IMMEDIATO=1
   else
      rm -f /tmp/dumpmx_nuovi_parametri 1>/dev/null 2>&1
      echo NUMERO_GIORNI_IN_LINEA"="`expr $NUM_GIORNI - 1` > /tmp/dumpmx_nuovi_parametri 
      tail -n +2 $UTILITY_DIR/dumpmx_parametri >> /tmp/dumpmx_nuovi_parametri 
      cp /tmp/dumpmx_nuovi_parametri    $UTILITY_DIR/dumpmx_parametri 
      rm /tmp/dumpmx_nuovi_parametri
      NUM_GIORNI=`grep NUMERO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
      Per_la_bacheca > /tmp/.oggi/dumpmx_troppo_pieno_msg  
      IMMEDIATO=0
   fi
   sh $UTILITY_DIR/centro_unificato_messaggi.sh DUMPGG Riduz_gg_dump_a_$NUM_GIORNI $IMMEDIATO 0 0 /tmp/.oggi/dumpmx_troppo_pieno_msg 
fi

if [ `date +%u` -eq 2 ] ; then
   NUM_GIORNI=`grep NUMERO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
   NUM_MINIMO_GIORNI=`grep NUMERO_MINIMO_GIORNI_IN_LINEA $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`
   if [ $NUM_GIORNI -lt $NUM_MINIMO_GIORNI ] ; then
      Check_settimanale > /tmp/.oggi/dumpmx_troppo_pieno_msg_check
      sh $UTILITY_DIR/centro_unificato_messaggi.sh DUMPGG GG_dump_inferiore_minimo 0 0 0 /tmp/.oggi/dumpmx_troppo_pieno_msg_check 
   fi
fi 

exit


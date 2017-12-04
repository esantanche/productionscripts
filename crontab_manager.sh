#!/bin/sh 
#

#****S* Helpers/Gestione crontab
#   NAME
#      crontab_manager Start e stop del crontab per interventi straordinari 
#   USAGE
#      Si puo' chiamare da crontab o da linea comando per disattivare o riattivare il crontab
#      dell'utente sybase 
#   PURPOSE
#      Lo script se chiamato con il parametro start riattiva il crontab dell'utente sybase
#      precedentemente disattivato da questo stesso script chiamato con il parametero stop. 
#      Al posto del crontab corrente viene messo un crontab praticamente vuoto di nome
#      file crontab_manager_crontab_vuoto al quale viene inoltre aggiunta una riga
#      contenente una sigla identificativa necessaria allo script per distinguere il
#      crontab "vuoto" da quello originale 
#   HISTORY
#      Versione iniziale 
#   INPUTS
#      Un solo parametro obbligatorio che vale start o stop 
#   OUTPUT
#      Non c'e' output se non in caso di errore.
#   RETURN VALUE
#      Nessun valore di ritorno.
#   EXAMPLE
#      Lo script viene tipicamente utilizzato negli interventi dei finesettimana 
#      per disattivare il crontab dell'utente sybase ed evitare cosi' segnalazioni
#      di errore superflue per es. nel caso in cui si eseguano degli shutdown degli ASE
#   ERRORS
#      Messaggio di errore nel caso al momento di far ripartire il crontab (opzione start)
#      non si trovasse il crontab salvato.
#***

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

if [ $1a = a ] ; then
   echo "Usage: $0 seguito dal comando:"
   echo "   start"
   echo "      rimette a posto il crontab dell'utente sybase come deve essere"
   echo "      per le normali operazioni"
   echo "   stop"
   echo "      azzera il crontab dell'utente sybase e lo sostituisce con quello"
   echo "      praticamente vuoto contenuto nel file crontab_manager_crontab_vuoto"
   exit 0
fi

cd $UTILITY_DIR

COMANDO=$1
STRINGA_RICONOSCIMENTO="CRONTAB_MANAGER_STOP_6TR43GI"

CRONTAB_FERMO=`crontab -l | grep $STRINGA_RICONOSCIMENTO | wc -l`

if [ $COMANDO = start -a $CRONTAB_FERMO -gt 0 ] ; then
   crontab -l > /tmp/.oggi/crontab_manager_salvataggio_di_sicurezza   
   if [ -e crontab_manager_crontab_salvato ] ; then
      crontab crontab_manager_crontab_salvato
   else
      echo Errore crontab salvato non presente
   fi
fi

if [ $COMANDO = stop -a $CRONTAB_FERMO -eq 0 ] ; then
   crontab -l > crontab_manager_crontab_salvato
   cat crontab_manager_crontab_vuoto > /tmp/.oggi/crontab_vuoto_con_stringa
   echo "# "$STRINGA_RICONOSCIMENTO >> /tmp/.oggi/crontab_vuoto_con_stringa
   crontab /tmp/.oggi/crontab_vuoto_con_stringa
fi

exit


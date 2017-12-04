#!/bin/sh -x

# ATTENZIONE ! questo script e' uguale su tutte le macchine per cui va modificato solo
# su mx1-dev-2 e poi copiato sulle altre macchine mediante lo script
# allinea_uno_script.sh    

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME
# HOME_OF_SYBASE
# PATH_ERRORLOG_ASESERVER

#. $HOME_OF_SYBASE/.profile

PRIOR_ERRORLOG=$UTILITY_DIR/out/aseserver_precedente.log
TAIL_ERRORLOG=$UTILITY_DIR/out/aseserver_tail_log_corrente.log
DIFF_ERRORLOG=$UTILITY_DIR/out/aseserver_diff.log
ERRORLOG=$PATH_ERRORLOG_ASESERVER

if [ ! -e "${ERRORLOG}" ] ; then
   echo Log non trovato probabilmente perche"'" in corso il troncamento del log
   exit
fi

# Se non esiste il precedente errorlog, procedo a crearlo per la prima volta
if [ ! -e "${PRIOR_ERRORLOG}" ] ; then

   ERRORLOG_ERROR_YN=`grep -E "Error:|infected|WARNING:|severity|encountered|Increase" ${ERRORLOG} | grep -vE "1608,|21,"`
   tail -n 1000 ${ERRORLOG} > ${PRIOR_ERRORLOG}

   #echo $ERRORLOG_ERROR_YN

   if [ ! -z "${ERRORLOG_ERROR_YN}" ] ; then
      echo "TROVATI ERRORI NEL LOG DELL'ASESERVER " $ASE_NAME
      echo "-------------------------------------------------------------------"
      grep -E "Error|infected|WARNING:|severity|encountered|Increase " ${ERRORLOG}
   fi

else

   tail -n 1000 ${ERRORLOG} > ${TAIL_ERRORLOG}
   diff ${TAIL_ERRORLOG} ${PRIOR_ERRORLOG} | grep \< | cut -c 2-200 > ${DIFF_ERRORLOG}
   cp ${TAIL_ERRORLOG} ${PRIOR_ERRORLOG}

   DIFF_ERRORLOG_ERROR_YN=`grep -E "Error:|infected|WARNING:|severity|encountered|Increase" ${DIFF_ERRORLOG} | grep -vE "1608,|21,"`

   if [ ! -z "${DIFF_ERRORLOG_ERROR_YN}" ] ; then
      echo "TROVATI ERRORI NEL LOG DELL'ASESERVER " $ASE_NAME
      echo "-------------------------------------------------------------------"
      grep -E "Error|infected|WARNING:|severity|encountered|Increase" ${DIFF_ERRORLOG}
   fi

fi



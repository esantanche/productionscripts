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
# PATH_ERRORLOG_BACKUPSERVER

. $HOME_OF_SYBASE/.profile

PRIOR_ERRORLOG=$UTILITY_DIR/out/backupserver_precedente.log
TAIL_ERRORLOG=$UTILITY_DIR/out/backupserver_tail_log_corrente.log
DIFF_ERRORLOG=$UTILITY_DIR/out/backupserver_diff.log
ERRORLOG=$PATH_ERRORLOG_BACKUPSERVER

if [ ! -e "${ERRORLOG}" ] ; then
   echo Log non trovato probabilmente perche"'" in corso il troncamento del log
   exit
fi

# Se non esiste il precedente errorlog, procedo a crearlo per la prima volta
if [ ! -e "${PRIOR_ERRORLOG}" ] ; then

   ERRORLOG_ERROR_YN=`grep "Backup Server:" ${ERRORLOG} | awk '{ split($0,a,"Backup Server:"); split(a[2],b,":"); split(b[1],c,".") ; if (c[3] != "1") { print $0; } ; }' `
   tail -n 1000 ${ERRORLOG} > ${PRIOR_ERRORLOG}

   #echo $ERRORLOG_ERROR_YN

   if [ ! -z "${ERRORLOG_ERROR_YN}" ] ; then
      echo "TROVATI ERRORI NEL LOG DEL BACKUP SERVER " $ASE_NAME
      echo "----------------------------------------------------------------"
      grep "Backup Server:" ${ERRORLOG} | awk '{ split($0,a,"Backup Server:"); split(a[2],b,":"); split(b[1],c,".") ; if (c[3] != "1") { print $0; } ; }'
   fi

else

   tail -n 1000 ${ERRORLOG} > ${TAIL_ERRORLOG}
   diff ${TAIL_ERRORLOG} ${PRIOR_ERRORLOG} | grep \< | cut -c 2-200 > ${DIFF_ERRORLOG}
   cp ${TAIL_ERRORLOG} ${PRIOR_ERRORLOG}

   DIFF_ERRORLOG_ERROR_YN=`grep "Backup Server:" ${DIFF_ERRORLOG} | awk '{ split($0,a,"Backup Server:"); split(a[2],b,":"); split(b[1],c,".") ; if (c[3] != "1") { print $0; } ; }' `

   if [ ! -z "${DIFF_ERRORLOG_ERROR_YN}" ] ; then
      echo "TROVATI ERRORI NEL LOG DEL BACKUP SERVER " $ASE_NAME
      echo "------------------------------------------------------------------"
      grep "Backup Server:" ${DIFF_ERRORLOG} | awk '{ split($0,a,"Backup Server:"); split(a[2],b,":"); split(b[1],c,".") ; if (c[3] != "1") { print $0; } ; }'
   fi

fi


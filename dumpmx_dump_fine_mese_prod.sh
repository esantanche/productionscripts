#!/bin/sh 
#

# Spazio libero minimo in KB
SOGLIA_SPAZIO_FS_DUMP_FINE_MESE=20000000

. /home/sybase/.profile

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ] ; then
   exit 0;
fi

if [ `hostname` != 'mx2-prod-pridb' ] ; then
   exit 0
fi

if [ `date +%d` -ne 1 ] ; then
   exit 0
fi

INIZIO_EPOCH=`epoch-it.pl`

cp $PATH_DUMP_DIR/dmpmx-CAP_MXPROD-`date +%Y%m%d`#* $PATH_DUMP_FINE_MESE 2>/dev/null
ERRCODE=$?

SPAZIO_LIBERO_FS_DUMP_FINE_MESE=`df -k $PATH_DUMP_FINE_MESE | grep -v Filesystem | awk '{ print $3; }'`

FINE_EPOCH=`epoch-it.pl`

if [ $ERRCODE -gt 0 ] ; then
   echo "Subject: [DUMPMXFINEMESE] ERRORE NEL COPIARE IL DUMP DI FINE MESE SU "$ASE_NAME >  /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "To: dba@kyneste.com"  >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "Si e' verificato un errore nel copiare il dump di fine mese come da TT 40432" >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "sulla macchina "`hostname` >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "    " >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "Provvedere a copiare in "$PATH_DUMP_FINE_MESE" e poi masterizzare il dump di CAP_MXPROD" >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "presente nella directory "$PATH_DUMP_DIR" con la data di oggi (primo del mese)" >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "perche' i dump vengono fatti dopo la mezzanotte in produzione" >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
else
   echo "Subject: [DUMPMXFINEMESE] OK per la copia del dump di fine mese" >  /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "To: dba@kyneste.com"  >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "Copia del dump di fine mese eseguita regolarmente sull'ASE "$ASE_NAME >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   echo "sulla macchina "`hostname` >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   if [ $SPAZIO_LIBERO_FS_DUMP_FINE_MESE -lt $SOGLIA_SPAZIO_FS_DUMP_FINE_MESE ] ; then
      echo "ATTENZIONE SPAZIO LIBERO SU F.S. "$PATH_DUMP_FINE_MESE" INSUFFICIENTE PER IL" >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
      echo "PROSSIMO DUMP" >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
      echo  $SPAZIO_LIBERO_FS_DUMP_FINE_MESE | awk '{ printf "Sono rimasti %5.1f GB\n",($1/1048576); }' >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
   fi
   echo "   " >> /tmp/.oggi/dumpmx_dump_fine_mese.mail
fi

echo $ERRCODE $INIZIO_EPOCH $FINE_EPOCH > /tmp/.oggi/dumpmx_dump_fine_mese
cat /tmp/.oggi/dumpmx_dump_fine_mese.mail >> /tmp/.oggi/dumpmx_dump_fine_mese

sh $UTILITY_DIR/centro_unificato_messaggi.sh COPIAFINEMESE CAP_MXPROD $ERRCODE $INIZIO_EPOCH $FINE_EPOCH /tmp/.oggi/dumpmx_dump_fine_mese.mail
rm -f /tmp/.oggi/dumpmx_dump_fine_mese.mail

exit $ERRCODE;

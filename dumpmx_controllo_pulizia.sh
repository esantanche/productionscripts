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

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

rm -f /tmp/lista_dir_bkp_notte
rm -f /tmp/differenze_files_dir_bkp_notte

ls -1 $PATH_DUMP_FS > /tmp/lista_dir_bkp_notte
diff /tmp/lista_dir_bkp_notte $UTILITY_DIR/out/lista_dir_bkp_notte | grep '<' > /tmp/differenze_files_dir_bkp_notte

if [ -s /tmp/differenze_files_dir_bkp_notte ] ; then
   #echo differenze presenti
   #echo elenco file da cancellare
   #cat /tmp/differenze_files_dir_bkp_notte | grep '<' | nawk -v bkp=$PATH_DUMP_FS '{ printf "rm -f %s/%s\n",bkp,$2; }' 
   echo "# file da cancellare" > /tmp/script_pulizia_bkp_notte
   for f in `cat /tmp/differenze_files_dir_bkp_notte | cut -d " " -f 2`   
   do
      echo "rm -f "$PATH_DUMP_FS"/"$f >> /tmp/script_pulizia_bkp_notte
   done
   echo "Subject: [CLEANUP] Cancellazione file estranei dir "$PATH_DUMP_FS" "$ASE_NAME  >  /tmp/cleanup.mail
   echo "To: dba@kyneste.com"  >> /tmp/cleanup.mail
   echo "(by dumpmx_controllo_pulizia.sh)" >> /tmp/cleanup.mail
   echo " " >> /tmp/cleanup.mail
   echo "C'erano file estranei nella dir "`hostname`":"$PATH_DUMP_FS >> /tmp/cleanup.mail
   echo "che ho cancellato per non pregiudicare le operazioni di dump" >> /tmp/cleanup.mail
   echo " " >> /tmp/cleanup.mail
   echo "Ecco lo script che ho eseguito:" >> /tmp/cleanup.mail
   echo " " >> /tmp/cleanup.mail
   cat /tmp/script_pulizia_bkp_notte >> /tmp/cleanup.mail
   #sh /tmp/script_pulizia_bkp_notte
   echo "ATTENZIONE NON ESEGUO LO SCRIPT!!! CANCELLATE MANUALMENTE!!!" >> /tmp/cleanup.mail
   cp /tmp/cleanup.mail /nagios_reps/File_estranei_dir_di_dump
   #/usr/sbin/sendmail -f cleanup@kyneste.com dba@kyneste.com < /tmp/cleanup.mail
   rm -f /tmp/cleanup.mail

   #echo File estranei in $PATH_DUMP_FS > /nagios_reps/File_estranei_dir_dump 
   #echo $(/usr/bin/date +%Y%m%d-%H%M) >> /nagios_reps/File_estranei_dir_dump
   #cat /tmp/script_pulizia_bkp_notte >> /nagios_reps/File_estranei_dir_dump
fi

#cat /tmp/lista_dir_bkp_notte

exit



#!/bin/sh 

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME
# SOGLIA_FS_DUMP_MB
# SOGLIA_FS_DB_MB

DATA=`date +%Y%m%d-%H:%M`

SPAZIO_LIBERO_FS_DUMP=`df -k | awk '/sybased1/ { print int($3 / 1000); }' `
#SPAZIO_LIBERO_FS_DB=`df -k | awk '/sybased2/ { print int($3 / 1000); }' `  

if [ $SPAZIO_LIBERO_FS_DUMP -lt $SOGLIA_FS_DUMP_MB ] ; then
   echo "==========================================================" >> $UTILITY_DIR/out/log_spazio_manovra
   echo "Data: " $DATA >> $UTILITY_DIR/out/log_spazio_manovra
   echo "Spazio libero rimasto su /sybased1: " $SPAZIO_LIBERO_FS_DUMP "Mb"  >> $UTILITY_DIR/out/log_spazio_manovra
   echo "Soglia impostata: " $SOGLIA_FS_DUMP_MB "Mb" >> $UTILITY_DIR/out/log_spazio_manovra

   echo "Subject: URGENTE SPAZIO MANOVRA ESAURITO !!!"  >  /tmp/manovra$$.mail
   #echo "Subject: 8G Murex " `hostname` " - Spazio di manovra "  >  /tmp/manovra$$.mail

   #echo "To: kymurex-tech@mlist.kyneste.com,dba@kyneste.com" 
   echo "To: dba@kyneste.com"  >> /tmp/manovra$$.mail

   #echo "ATTENZIONE!! APPLICARE LA PROCEDURA DI GESTIONE DEI THRESHOLD" 
   #echo "PRESENTE SUL MANUALE DI IMPIANTO" 
   
   echo "Eseguire la seguente procedura:" >> /tmp/manovra$$.mail
   echo "1) Pulire la directory /sybased1 da eventuali file obsoleti" >> /tmp/manovra$$.mail
   echo "2) Se non si e' potuto ricavare spazio, chiedere subito ai sistemisti" >> /tmp/manovra$$.mail
   echo "   di ampliare il file system /sybased1 di almeno 1 Gb " >> /tmp/manovra$$.mail
   #echo "ulteriormente" >> /tmp/manovra$$.mail

   #  PER IL MESSAGGIO ESECUTIVO SCRIVI CHE VA CONTROLLATA L'IMMONDIZIA PRIMA DI FAR AMPLIARE

   echo "--------------------------------------------------------------------------------------" >> /tmp/manovra$$.mail

   echo "Lo spazio di manovra nel file system /sybased1 su " `hostname` " e' di " >> /tmp/manovra$$.mail
   echo $SPAZIO_LIBERO_FS_DUMP " Mb liberi" >> /tmp/manovra$$.mail 
   echo "inferiore alla soglia di " $SOGLIA_FS_DUMP_MB "Mb" >> /tmp/manovra$$.mail       

   /usr/sbin/sendmail -f murex@kyneste.com dba@kyneste.com < /tmp/manovra$$.mail       

   rm /tmp/manovra$$.mail       
fi



#echo "--------------------------------------------------------------------------------------" >> /tmp/thr$$.mail
#echo "PROGETTO MUREX" >> /tmp/thr$$.mail
#echo "Hostname:      " `hostname` >> /tmp/thr$$.mail
#echo "Date:           $DATA  "  >> /tmp/thr$$.mail
#echo "Problem: Threshold superato" >> /tmp/thr$$.mail
#echo "Database:      " $1 >> /tmp/thr$$.mail

#echo "Segmento:      " $2 >> /tmp/thr$$.mail
#echo "Soglia in Mb:  " $SOGLIA >> /tmp/thr$$.mail
#echo "--------------------------------------------------------------------------------------" >> /tmp/thr$$.mail

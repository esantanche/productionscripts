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
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi


cat $PATH_LOG_TIVOLI | grep "Elapsed processing time" > /tmp/tempi-impiegati-backup-tivoli.1
cat $PATH_LOG_TIVOLI | grep "Total number of bytes transferred" >> /tmp/tempi-impiegati-backup-tivoli.1
#cat $PATH_LOG_TIVOLI | grep "Aggregate data transfer rate" >> /tmp/tempi-impiegati-backup-tivoli.1
cat $PATH_LOG_TIVOLI | grep "data transfer rate" >> /tmp/tempi-impiegati-backup-tivoli.1

cat /tmp/tempi-impiegati-backup-tivoli.1 | sort | tail -20  > /tmp/tempi-impiegati-backup-tivoli.2

cat /tmp/tempi-impiegati-backup-tivoli.2 | cut -c -8  | uniq | awk '{ print $1," ====================="; }' >> /tmp/tempi-impiegati-backup-tivoli.2

cat /tmp/tempi-impiegati-backup-tivoli.2 | sort > $UTILITY_DIR/out/tempi-impiegati-backup-tivoli

echo "Subject: [BACK_TIVOLI] Tempi impiegati backup Tivoli su host "`hostname` >  /tmp/tempi-impiegati-backup-tivoli.mail
echo "To: dba@kyneste.com"  >> /tmp/tempi-impiegati-backup-tivoli.mail
echo "(by tempi-impiegati-backup-tivoli.sh)" >> /tmp/tempi-impiegati-backup-tivoli.mail
echo "===================================================" >> /tmp/tempi-impiegati-backup-tivoli.mail
cat $UTILITY_DIR/out/tempi-impiegati-backup-tivoli >> /tmp/tempi-impiegati-backup-tivoli.mail

/usr/sbin/sendmail -f tempitivoli@kyneste.com dba@kyneste.com < /tmp/tempi-impiegati-backup-tivoli.mail

rm -f /tmp/tempi-impiegati-backup-tivoli.*

exit


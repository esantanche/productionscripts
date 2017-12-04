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

DATA=$(/usr/bin/date +%Y%m%d)

echo "Subject: Report tempdb e connessioni "$ASE_NAME >  /tmp/repo-tempdb-conn.mail
echo "To: dba@kyneste.com"  >> /tmp/repo-tempdb-conn.mail
echo "ASE - "$ASE_NAME >> /tmp/repo-tempdb-conn.mail 
echo "Numero connessioni attive" >> /tmp/repo-tempdb-conn.mail
echo "===================================================" >> /tmp/repo-tempdb-conn.mail
tail -4 $UTILITY_DIR/out/log-numero-processi >> /tmp/repo-tempdb-conn.mail
echo " " >> /tmp/repo-tempdb-conn.mail
echo "Spazio occupato tempdb" >> /tmp/repo-tempdb-conn.mail
echo "===================================================" >> /tmp/repo-tempdb-conn.mail
tail -4 $UTILITY_DIR/out/spazio-db-tempdb >> /tmp/repo-tempdb-conn.mail

/usr/sbin/sendmail -f repotempconn@kyneste.com dba@kyneste.com < /tmp/repo-tempdb-conn.mail

rm -f /tmp/repo-tempdb-conn.mail


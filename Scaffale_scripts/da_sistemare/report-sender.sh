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

WORK_DIR=$UTILITY_DIR

cd ${WORK_DIR}/out

#NUMERO_FILES=`ls -p1t $1* 2>/dev/null | wc -l`
NUMERO_FILES=`find . -name "$1*" -mtime -10 2>/dev/null | wc -l`

if [ $NUMERO_FILES -eq 0 ] ; then
   exit 0
fi

echo Report sender > /tmp/report-sender
echo All files beginning by $1 >> /tmp/report-sender
echo Reporting only files not older then 10 days >> /tmp/report-sender

for file in `find . -name "$1*" -mtime -5`
do
       # Invio solo i file modificati negli ultimi 5 giorni
       # ovvero non invio file fermi da piu' di 5 gg
       echo ======================================================================= >> /tmp/report-sender
       echo File ${file} ============= >> /tmp/report-sender
       tail -10 ${file} >> /tmp/report-sender
done

echo "Subject: [REPORT-SENDER] Sending "$1"'s from "`hostname` >  /tmp/report-sender.mail
echo "To: dba@kyneste.com"  >> /tmp/report-sender.mail
echo "(Made by $UTILITY_DIR/report-sender.sh $1)"  >> /tmp/report-sender.mail
#echo "===================================================" >> /tmp/report-sender.mail 
cat  /tmp/report-sender  >> /tmp/report-sender.mail
#echo "===================================================" >> /tmp/report-sender.mail

/usr/sbin/sendmail -f reposender@kyneste.com dba@kyneste.com < /tmp/report-sender.mail 

#rm -f /tmp/report-sender* 

exit


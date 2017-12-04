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

# Soglia spazio libero su sybasevg
SOGLIA=10

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

SPAZIO=`lsvg -p sybasevg | awk 'BEGIN { sum=0; } { sum=sum+$4; } END { printf "%5.1f\n",sum * 32 / 1024; }'`

DATA=$(/usr/bin/date +%Y%m%d)

SPAZIO_PREC=`tail -1 $UTILITY_DIR/out/report-spazio-libero-sybasevg | awk '{ print $2; }'`
#echo $SPAZIO $SPAZIO_PREC

DIFF=`echo $SPAZIO $SPAZIO_PREC | awk '{ print ($1 != $2); }'`

#echo $DIFF

if [ $DIFF -eq 1 ] ; then
   #echo $DATA $SPAZIO Gb
   echo $DATA $SPAZIO Gb >> $UTILITY_DIR/out/report-spazio-libero-sybasevg
fi
#echo $SPAZIO Gb

SPAZIO_LIBERO_SOTTO_SOGLIA=`echo $SPAZIO $SOGLIA | awk '{ print ($1 < $2); }'`

GIORNO=$(/usr/bin/date +%d)

if [ $GIORNO -eq 15  -a $SPAZIO_LIBERO_SOTTO_SOGLIA -eq 1 ] ; then

   echo "Subject: Liberi "$SPAZIO" Gb su sybasevg - host "`hostname` >  /tmp/repo-spazio-vg.mail
   echo "To: dba@kyneste.com,mx-gov@kyneste.com,gsacco@kyneste.com"  >> /tmp/repo-spazio-vg.mail
   echo "Disponibili "$SPAZIO" Gb su sybasevg - host "`hostname` >> /tmp/repo-spazio-vg.mail  
   #echo "===================================================" >> /tmp/repo-spazio-vg.mail 
   #cat  $UTILITY_DIR/repo-spazi-liberi-vg-spiegazioni  >> /tmp/repo-spazio-vg.mail
   echo "===================================================" >> /tmp/repo-spazio-vg.mail
   tail -10 $UTILITY_DIR/out/report-spazio-libero-sybasevg >> /tmp/repo-spazio-vg.mail

   sh $UTILITY_DIR/centro_unificato_messaggi.sh VGCHECK Meno_di_${SOGLIA}_gb 0 0 0 /tmp/repo-spazio-vg.mail

   rm -f /tmp/repo-spazio-vg.mail 

fi

exit



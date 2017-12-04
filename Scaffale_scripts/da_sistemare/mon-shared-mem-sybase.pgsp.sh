#!/bin/sh 
#

ORA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != root ] ; then
   echo Eseguire come root
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

exit

PGSP=`svmon -U sybase | grep "^sybase" | awk '{ print $4*4096; }'

PGSP=`svmon -U sybase -w | grep "work text data BSS heap" | nawk 'BEGIN { sum=0; }
                                                                        { sum1=sum1+$11; }
                                                                  END { sum1=sum1/(262144); 
                                                                        printf "%5.0f\n",sum1*10; }'`


# Attenzione PGSP e' espresso in decimi di GB ovvero per es. 0.2 GB equivalgono a PGSP=2

if [ $PGSP -lt 2 ] ; then
   #echo Ho trovato tutti zeri
   #echo mon-shared
   exit 0
fi

if [ -s $UTILITY_DIR/out/mon-shared-mem-pgsp-current-values ] ; then
   OLD_PGSP=`cat $UTILITY_DIR/out/mon-shared-mem-pgsp-current-value`
   REGISTRARE_DIFF=`echo $PGSP $OLD_PGSP | awk '{ diff=$1-$2; if (diff < 0) diff=-diff;
                                                  if (diff > 2) print 1; else print 0; }'
   if [ $REGISTRARE_DIFF -gt 0 ] ; then
      echo $PGSP > $UTILITY_DIR/out/mon-shared-mem-pgsp-current-value
      echo $ORA $PGSP | awk '{ printf "%-13s %5.1f\n", $1,$2/10; }' >> $UTILITY_DIR/out/mon-shared-mem-pgsp
   fi
else
   echo $PGSP > $UTILITY_DIR/out/mon-shared-mem-pgsp-current-value
fi

#$UTILITY_DIR/out/mon-shared-mem-current-values

exit


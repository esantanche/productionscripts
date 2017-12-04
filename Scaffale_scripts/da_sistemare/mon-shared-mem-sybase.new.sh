#!/bin/sh 
#

ORA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != root ] ; then
   echo Eseguire come root
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

exit

svmon -U sybase -w | grep "work text data BSS heap" | nawk 'BEGIN { sum1=0; sum2=0; sum3=0; sum4=0 }
                                                        { sum1=sum1+$9; sum2=sum2+$10; sum3=sum3+$11; sum4=sum4+$12; }
                                                        END { sum1=sum1/(262144); 
                                                              sum2=sum2/(262144);
                                                              sum3=sum3/(262144);
                                                              sum4=sum4/(262144);
                                                              z1=int(sum1/2);
                                                              z2=int(sum2/2);
                                                              z3=int(sum3/2);
                                                              z4=int(sum4/2);
                                                              printf "%5.1f %5.1f %5.1f %5.1f\n",z1,z2,z3,z4; }' > /tmp/mon-shared-mem-current-values

# controllo che non siano tutti zeri
SOMMO_TUTTO=`cat /tmp/mon-shared-mem-current-values | awk '{ print ($1+$2+$3+$4)*1000; }'`
#echo mon-shared somma $SOMMO_TUTTO

if [ $SOMMO_TUTTO -lt 100 ] ; then
   #echo Ho trovato tutti zeri
   #echo mon-shared
   exit 0
fi

if [ -s $UTILITY_DIR/out/mon-shared-mem-current-values ] ; then
   diff /tmp/mon-shared-mem-current-values $UTILITY_DIR/out/mon-shared-mem-current-values >/dev/null
   DIFFERENZA_PRESENTE=$?
   #DIFFERENZA_PRESENTE=1
   if [ $DIFFERENZA_PRESENTE -gt 0 ] ; then
      cp /tmp/mon-shared-mem-current-values $UTILITY_DIR/out/mon-shared-mem-current-values
      echo "$ORA $(cat /tmp/mon-shared-mem-current-values) Inuse Pin Pgsp Virt" >> $UTILITY_DIR/out/mon-shared-mem-sintetico
      tail -5 $UTILITY_DIR/out/mon-shared-mem-sintetico
   fi
else
   cp /tmp/mon-shared-mem-current-values $UTILITY_DIR/out/mon-shared-mem-current-values
fi

#$UTILITY_DIR/out/mon-shared-mem-current-values

exit


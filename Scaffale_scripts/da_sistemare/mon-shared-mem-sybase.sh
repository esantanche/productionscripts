#!/bin/sh 
#

if [ $USER != root ] ; then
   echo Eseguire come root
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

for i in 1 2 3 4 5
do
   #echo $i
   svmon -U sybase -w | grep "work text data BSS heap" | nawk 'BEGIN { sum1=0; sum2=0; sum3=0; sum4=0 }
                                                        { sum1=sum1+$9; sum2=sum2+$10; sum3=sum3+$11; sum4=sum4+$12; }
                                                        END { sum1=sum1/(262144); 
                                                              sum2=sum2/(262144);
                                                              sum3=sum3/(262144);
                                                              sum4=sum4/(262144);
                                                              printf "%5.1f %5.1f %5.1f %5.1f\n",sum1,sum2,sum3,sum4; }' > /tmp/mon-shared-mem-current-values

   # controllo che non siano tutti zeri
   SOMMO_TUTTO=`cat /tmp/mon-shared-mem-current-values | awk '{ print ($1+$2+$3+$4)*1000; }'`
   #echo mon-shared somma $SOMMO_TUTTO

   if [ $SOMMO_TUTTO -gt 100 ] ; then
      break
   fi

   sleep 60

done

ORA=$(/usr/bin/date +%Y%m%d-%H%M)

echo "$ORA $(cat /tmp/mon-shared-mem-current-values)" | nawk '{ printf "%-13s Inuse %5.1f Pin %5.1f Pgsp %5.1f Virtual %5.1f GB\n",$1,$2,$3,$4,$5; }' >> $UTILITY_DIR/out/mon-shared-mem

exit


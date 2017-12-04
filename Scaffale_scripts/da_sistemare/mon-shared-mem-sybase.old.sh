#!/bin/sh 
#

ORA=$(/usr/bin/date +%Y%m%d-%H%M)

if [ $USER != root ] ; then
   echo Eseguire come root
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

svmon -U sybase | grep "work text data BSS heap" | nawk -v ora=$ORA 'BEGIN { sum1=0; sum2=0; sum3=0; sum4=0 }
                                                        { sum1=sum1+$9; sum2=sum2+$10; sum3=sum3+$11; sum4=sum4+$12; }
                                                        END { sum1=sum1*4096;
                                                              sum2=sum2*4096;
                                                              sum3=sum3*4096;
                                                              sum4=sum4*4096;
                                                              sum1=sum1/(1073741824);
                                                              sum2=sum2/(1073741824);
                                                              sum3=sum3/(1073741824);
                                                              sum4=sum4/(1073741824);
                                                              printf "%-13s Inuse %5.1f Pin %5.1f Pgsp %5.1f Virtual %5.1f\n",ora,sum1,sum2,sum3,sum4; }' >> $UTILITY_DIR/out/mon-shared-mem

echo Valori registrati in $UTILITY_DIR/out/mon-shared-mem
tail -5 $UTILITY_DIR/out/mon-shared-mem

exit


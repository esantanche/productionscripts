#!/bin/sh

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

PATH_LAST=$UTILITY_DIR/Scaffale_scripts/maint/allinea_scaffale_scripts.last
PATH_REP=$UTILITY_DIR/Scaffale_scripts/maint/allinea_scaffale_scripts.report

cd $UTILITY_DIR/Scaffale_scripts

if [ -e $PATH_LAST ] ; then
   find . -newer $PATH_LAST > /tmp/.oggi/allinea_scaffale_scripts.list 
else
   # Il file contenente l'ultima data ora di allineamento non esiste
   # va fatto un allineamento completo
   find . > /tmp/.oggi/allinea_scaffale_scripts.list
fi

if [ ! -s /tmp/.oggi/allinea_scaffale_scripts.list ] ; then
   echo "Non ci sono file da allineare"
   exit 0
fi

#cat /tmp/.oggi/allinea_scaffale_scripts.list

echo Tar ...

rm -f /tmp/.oggi/allinea_scaffale_scripts.tar
tar -cvf /tmp/.oggi/allinea_scaffale_scripts.tar -L /tmp/.oggi/allinea_scaffale_scripts.list > $PATH_REP

echo Scp ...

PATH_TAR=/tmp/.oggi/allinea_scaffale_scripts.tar
scp $PATH_TAR mx2-test-1:/tmp/.oggi >> $PATH_REP
scp $PATH_TAR mx2-pridb:/tmp/.oggi  >> $PATH_REP
scp $PATH_TAR mx1-secdb:/tmp/.oggi  >> $PATH_REP

echo Untar a destinazione ...
 
ssh mx2-test-1 "cd $UTILITY_DIR/Scaffale_scripts; tar -xvf /tmp/.oggi/allinea_scaffale_scripts.tar" >> $PATH_REP 
ssh mx2-pridb  "cd $UTILITY_DIR/Scaffale_scripts; tar -xvf /tmp/.oggi/allinea_scaffale_scripts.tar" >> $PATH_REP
ssh mx1-secdb  "cd $UTILITY_DIR/Scaffale_scripts; tar -xvf /tmp/.oggi/allinea_scaffale_scripts.tar" >> $PATH_REP

date +%Y.%m.%d-%H:%M > $PATH_LAST

exit


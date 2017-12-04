#!/bin/sh

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

cd $UTILITY_DIR

PATH_LISTA=/tmp/.oggi/maint_bkp_per_meteora.list

( find . -name "*.sh" ; find . -name "*.pl" ) > $PATH_LISTA

rm -f bkp_scripts_murex.*
tar -cvf bkp_scripts_murex.tar -L $PATH_LISTA > /dev/null

gzip bkp_scripts_murex.tar

exit



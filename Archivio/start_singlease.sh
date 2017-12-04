#!/bin/sh
#

/sybase/ASE-12_5/install/startserver -f /sybase/ASE-12_5/install/RUN_MX1_DEV_2 -m
sleep 10
/sybase/ASE-12_5/install/startserver -f /sybase/ASE-12_5/install/RUN_MX1_DEV_2_back
sleep 10
#/sybase/ASE-12_5/install/startserver -f /sybase/ASE-12_5/install/RUN_MX1_DEV_2_mon
echo
exit 0


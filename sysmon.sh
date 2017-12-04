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


SCRIPT_NAME=`basename $0`

#if  [ $# -ne 1 ]
#then
#	echo "\nUsage: ${SCRIPT_NAME} <ASE_Server>\n"
#	exit
#fi

SERVER_NAME=$ASE_NAME

DAILY_DIR=`date '+%Y_%m_%d'`
FILE_DATA=`date '+%Y%m%d-%H%M'`

SYBASE=/sybase
. ${SYBASE}/SYBASE.sh

WORK_DIR=$UTILITY_DIR
OUT_DIR=${WORK_DIR}/sysmondir/${DAILY_DIR}

FILE_IN=${WORK_DIR}/sysmon.sql
FILE_OUT=${OUT_DIR}/sysmon_${SERVER_NAME}_${FILE_DATA}.out

#######################
#       M A I N       #
#######################

mkdir -p ${OUT_DIR}

${SYBASE}/${SYBASE_OCS}/bin/isql -U${SAUSER} -S${SERVER_NAME} -w2000 -I ${SYBASE}/interfaces -n -b -i${FILE_IN} -o ${FILE_OUT} -P${SAPWD}

#sleep 10

ENGINE=`grep "                  Average" ${FILE_OUT} | awk '{ print $2; }'` 
XACT=`grep "Committed Xacts" ${FILE_OUT} | awk '{ print $3; }'`
echo $FILE_DATA $ENGINE $XACT | awk '{ printf "%s Engine= %6.1f Xact= %6.1f \n",$1,$2,$3 ; }'   >> ${WORK_DIR}/sysmondir/sysmon_summary_${DAILY_DIR}.sum

for file in `ls ${OUT_DIR}/*.out`
do
	gzip -9 ${file}
done

exit 0

#!/bin/sh 
#

echo SCRIPT OBSOLETO

exit 0

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

DIR_TO_CLEAN=/sybased2
NO_CLEAN=databases

# Cancella tutto tranne le directory (-type d), i file che hanno nel path
# la stringa $NO_CLEAN e i file LEGGIMI
for j in `find $DIR_TO_CLEAN ! -type d | grep -v $NO_CLEAN | grep -v LEGGIMI`
do
   rm -f $j
done 

exit



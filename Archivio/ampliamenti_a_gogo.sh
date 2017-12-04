#!/bin/sh

# Questo script amplia diversi db usando lo script db-ampliamento-dati.sh 

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

cd $UTILITY_DIR

echo "Inserisci la size di ampliamento in MB"
read size
echo " "
echo " "

sh db-ampliamento-misto.sh CAP_REPORT $size
echo Premere Invio
read
sh db-ampliamento-misto.sh CAP_SVIL   $size
echo Premere Invio
read
sh db-ampliamento-misto.sh CAP_TEST   $size

exit




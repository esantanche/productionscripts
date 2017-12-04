#!/bin/sh 
#

#DATA=$(/usr/bin/date +%Y%m%d)

# Script per ridurre i Persistent Large Files

if [ $USER != root ] ; then
   echo Eseguire come root
   exit 0
fi

echo Riduzione PLF sulle macchine Murex

# Innanzitutto imposto la percentuale max dei PLF al 40% in modo appunto da ridurre i PLF
/usr/samples/kernel/vmtune -p10 -P40 -t40   
# La percentuale deve essere rispettata rigorosamente
/usr/samples/kernel/vmtune -h 1

# Poi aspetto per permettere al sistema operativo di pulire i PLF
sleep 600 

# Poi reimposto le percentuali
/usr/samples/kernel/vmtune -p20 -P80 -t80 
/usr/samples/kernel/vmtune -h 0

exit


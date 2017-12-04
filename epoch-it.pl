#!/usr/bin/perl

# Questo script restituisce l'epoch di creazione di un file oppure l'epoch
# corrente se non viene dato il path del file

$path=$ARGV[0];

if (defined($path)) {
   
   ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                  $atime,$mtime,$ctime,$blksize,$blocks)
                   = stat($path);
   print $mtime,"\n"; 

} else {
   print time,"\n";

}


exit;


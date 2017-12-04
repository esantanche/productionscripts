#!/usr/bin/perl

# Prove per data di ieri

$aggiunta=$ARGV[0];

if (!defined($aggiunta)) {
   print "usage: perl $0 <ore da aggiungere alla data attuale, negativo per sottrarre>\n\n";
   exit;
}

#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime(time);

#$annomesegiorno = (((($year+1900) * 10000) + ($mon+1) * 100) + $mday);

#print "oggi = ",($year+1900),".",($mon+1),".",$mday,"\n";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime(time + $aggiunta*(60*60));

#$annomesegiorno = (((($year+1900) * 10000) + ($mon+1) * 100) + $mday);

#print "fra ",$aggiunta," giorni = ",($year+1900),".",($mon+1),".",$mday,""\n";
printf "%04d%02d%02d%02d%02d\n",($year+1900),($mon+1),$mday,$hour,$min;



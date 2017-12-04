#!/usr/bin/perl

$epoch=$ARGV[0];

if (!defined($epoch)) {
   print "usage: perl $0 <epoch da convertire in data-ora>\n\n";
   exit;
}

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime($epoch);

printf "%04d.%02d.%02d-%02d:%02d:%02d\n",($year+1900),($mon+1),$mday,$hour,$min,$sec;



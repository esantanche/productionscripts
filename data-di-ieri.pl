#!/usr/bin/perl

$epoch = time - 86400;

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = localtime($epoch);

#printf "%04d.%02d.%02d-%02d:%02d:%02d\n",($year+1900),($mon+1),$mday,$hour,$min,$sec;
printf "%04d%02d%02d\n",($year+1900),($mon+1),$mday;



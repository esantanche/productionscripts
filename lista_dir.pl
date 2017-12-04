#!/usr/bin/perl -w

#use IO::File;
use Fcntl ':mode';

$dir_da_vedere=$ARGV[0];

print "Lista della directory ",$dir_da_vedere,"\n";

use IO::Dir;

$d = IO::Dir->new($dir_da_vedere);

if (defined $d) {
   while (defined($_ = $d->read)) { 
      next if (/nohup.out/);
      #print $_,"\n";
      ($n,$n,$mode,$n,$n,$n,$n,$size,
                  $n,$mtime,$n,$n,$n)
                   = stat($dir_da_vedere . "/" . $_);
      next if (S_ISDIR($mode));
      ($sec,$min,$hour,$mday,$mon,$year,$n,$n,$n) =
                                                localtime($mtime);
      #$size= -s $dir_da_vedere . "/" . $_;
      printf "%12d %4d.%02d.%02d-%02d:%02d:%02d %-60s\n",$size,$year+1900,$mon+1,$mday,$hour,$min,$sec,$_;

   }
   #$d->rewind;
   #while (defined($_ = $d->read)) { something_else($_); }
   undef $d;
}

$sec=$n;

exit;

#           ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
#                  $atime,$mtime,$ctime,$blksize,$blocks)
#                   = stat($_);


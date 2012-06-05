#!usr/bin/perl

use warnings;
use strict;

BEGIN{
require '/home/satyap/blosxom/config.pl';
use vars qw[$mydir $datadir $ext $datfile $find $md5sum];
push @INC,$mydir;
}

use LJPost;

my @files=`$find . -name "*.$ext" -print`;
my %sums;
my ($sum,$file);

open(I,"<$datfile") || die "$datfile: $!";
while(<I>) {
    chomp;
    next if /^$/ || /^#/;
    ($file,$sum)=split(/\s+/,$_);
#    print $file,$sum . "\n\n";
    $sums{$file}=$sum;
    }
close(I);

foreach $file (@files) {
    chomp($file);
    $sum=(split(/\s+/,`$md5sum $file`))[0];
    next if $sums{$file} && $sum eq $sums{$file};
    $sums{$file}=$sum;
#    &send2lj($file);
    }

#delete elements from %sum which don't exist in $file;
my %s2;
foreach $file (@files) {
    $s2{$file}=$sums{$file};
    }
%sums=%s2;

&writedat($datfile,\%sums);

exit;


__END__

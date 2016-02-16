#!/usr/bin/perl

#use warnings;

@dirs=`find . -maxdepth 1 -type d`;

#print @files;

shift(@dirs);
@dirs=sort(@dirs);
foreach $dir (@dirs) {
chomp($dir);
$dir=~ s/\s+//g;
$dir=~ s!^\./!!g;
chomp(@lines=`fgrep -a "!   " "$dir/$ARGV[0]" |tail`);
unless(@lines) {next};
$lines[-1] =~m/(-\d+\.\d+)/;
$enlast=$1;
$lines[-2] =~m/(-\d+\.\d+)/;
$ennotlast=$1;
$diff=$enlast-$ennotlast;
print "$dir   EN: $enlast  Conv: $diff\n";} 

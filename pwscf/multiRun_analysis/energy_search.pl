#!/usr/bin/perl

#use warnings;

unless(@ARGV) {
	$name=`find \$(pwd) -maxdepth 1 -type f -name '*out'`;
    chomp($name);
    @list=split('\n',$name);
    push(@files,@list) ;
} else {
    @files=@ARGV;
}

foreach $file (@files)
{
    #print @files;
    chomp(@lines=`fgrep -a "!   " "$file" |tail`);
    unless(@lines) {next};
    $lines[-1] =~m/(-\d+\.\d+)/;
    $enlast=$1;
    $lines[-2] =~m/(-\d+\.\d+)/;
    $ennotlast=$1;
    $diff=$enlast-$ennotlast;
    #print @lines;
    print "$file EN: $enlast  Conv: ";
    printf("%e\n",$diff);
}

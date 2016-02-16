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
    chomp(@lines=`fgrep -a "Fermi ener" "$file" |tail`);
#    print @lines;
    print "$file $lines[-1]\n";
}

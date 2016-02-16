#!/usr/bin/perl
use warnings;
use strict;
###########################

my (@pbs, $input_file);
opendir(DIR,".") or die "opening directory failed:$!";  
my @files=readdir(DIR);
foreach(@files)
{
    if (@ARGV<1) { if($_=~/pbs$/) {push @pbs, $_;} }
    else {$pbs[0]=$ARGV[0];}
}
closedir(DIR);
if(@pbs==1){$input_file=$pbs[0];}
else{die "Too many pbs files found.\n Give the one you want as a commandline argument."; }

open (PBSFILE, "<", "$input_file") or die "Can't find $input_file!" ;


my (@pos_raw, @pos, $nat);
while(<PBSFILE>) 
{
	if (/ATOMIC_POSITIONS / .. /K_POINTS AUTOMATIC/) {push @pos_raw,$_;}
    if (/\s+nat\s*=\s*(\d+)\s*,/) {$nat=$1}
}

foreach (@pos_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @pos, $_} }
my $atom_number=@pos;
unless($nat==$atom_number){print "nat changed from $nat to $atom_number\n"}

#system("echo 's/(\\s+nat\\s+=\\s*)\\d+\\s*(,)/\$\{1\}$atom_number\$\{2\}/' ");
system("perl -p -i -e 's/(\\s+nat\\s+=\\s*)\\d+\\s*(,)/\$\{1\}$atom_number\$\{2\}/' $input_file");


# I tried to do a one-liner like this, but this script was easier
#    alias natFix=" perl -p -i -e 's/(\s*nat\s+=\s+)\d+/${1}`perl -ne 
#\'print if /ATOMIC_POSITIONS {crystal}/ .. /K    _POINTS AUTOMATIC/\' *.pbs|grep \'[0-9]\'`' "




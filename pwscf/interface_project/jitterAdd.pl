#!/usr/bin/perl
#
#use warnings;
#use strict; 

#This adds random noise to all of positions in a box specified by 6 commandline arguments

my ($xmin, $xmax, $ymin, $ymax, $zmin, $zmax);
$xmin=$ARGV[0];
$xmax=$ARGV[1];
$ymin=$ARGV[2];
$ymax=$ARGV[3];
$zmin=$ARGV[4];
$zmax=$ARGV[5];

######  FILE Open Operation
my $pbsfile;
###########################
{ #Start read operation
my @pbsfiles;my $input_file;
opendir(DIR,".") or die "opening directory failed:$!";  
my @files=readdir(DIR);
foreach(@files)
{
    if($_=~/pbs$/) {push @pbs, $_;} 
}
closedir(DIR);
if(@pbs==1){$input_file=$pbs[0];}
else{die "Too many pbs files found.\n" }
#I could do something really clever with a diff on the .in file for multiple pbs files.

open (PBSFILE, "<", "$input_file") or die "Can't find $input_file!" ;
$pbsfile = do { local $/; <PBSFILE> };

#print "Input is $input_file\n";
if($input_file =~ /next1\.pbs/){die "next1.pbs file already exists\n";}
close PBSFILE;
open PBSFILE, "<", "$input_file";
} #End file read operation
###########################


#############
#Define Read Pos
#############

while(<PBSFILE>)
{
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @pos_raw,$_;}
}

@pos=&pretty_pos(@pos_raw);

foreach $line (@pos)
{
    if($line =~ m/\s*\w+\s+(\d\.\d+)\s+(\d\.\d+)\s(\d\.\d+)/)
    {
        $x=$1; $y=$2; $z=$3;
        if( $xmin < $x && $x< $xmax && $ymin < $y && $y < $ymax && $zmin < $z && $z < $zmax )
        {
 #          print $line;
           $line =~ s/$x/($x+(rand()-0.5)*0.1)/e;
           $line =~ s/$y/($y+(rand()-0.5)*0.1)/e;
           $line =~ s/$z/($z+(rand()-0.5)*0.1)/e;
#           print $line;
        }
    }
}

$pbsfile=~ s/ATOMIC_POSITIONS\s*{crystal}.*K_POINTS AUTOMATIC/@pos/s;


open OUTPUT, ">", "next1.pbs" or die "Can't create Output\n";
print OUTPUT $pbsfile;
close OUTPUT;



sub pretty_pos
{
    foreach (@_)
    {
    ~ s/\s.*e-.*\s/ 0 /;
    ~ s/\s0\s/ 0.00 /;
    if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}
    if (/\s1\./) {~ s/(\s1\.)/\t0./g}

    if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
    {$_=sprintf( "%s\t%.8f %.8f %.8f\n" , $1, $2, $3, $4 )}
    }
    return @_;
}

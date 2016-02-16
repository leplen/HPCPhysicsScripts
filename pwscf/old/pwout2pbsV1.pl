#!/usr/bin/perl

#This script takes as input a pwscf output file and a pbs filed and edits the pbs file to have the final positions and lattice parameters from the output file.
#verson_1.0 written by N.Lepley 11/2012
# The pbs file it generates is named next.pbs. The pwscf run it is based on has to have finished (printed the final coordinates) for the regexes to work
#
#
#This isn't actually closely related to pwout2pbsV2.pl, which does a better job handling runs that didn't finish gracefully,
#but also punts to PWscf_triclinc for the lattice stuff.
use warnings;
use PDL;
#use strict;
#use PDL::NiceSlice;
use PDL::Basic;

#If uncommented prints a little extra information in case of errors
my $verbose=1;

my @positions;
my $crystal_cell=pdl;

#This brace scopes Block 1 which is reponsibile for reading the output file and storing the
#positions in crystal coordinates (in @positions) and the crystal lattice vectors (in $crystal_cell).


print "Assuming output file is $ARGV[0]\n";
open OUTPUTFILE, "<", "$ARGV[0]" or die "Couldn't open $!";
my $alat;
my @positions_raw;
my @crystal_axes_raw;
while(<OUTPUTFILE>) 
{
	if (/Begin final coordinates/ .. /End final coordinates/) {push @positions_raw,$_;}
	if (/lattice parameter \(alat\)\s+=\s+(\d+\.\d+)/) {$alat=$1}
	#if (/crystal axes/ .. /reciprocal axes/) {push @crystal_axes_raw,$_};  #for "relax"
	
}

foreach(@positions_raw) {if (/CELL_PARAMETERS/ .. /ATOMIC_POSITIONS/) {push @crystal_axes_raw,$_}}  #for vc-relax
print "Assuming base pbs file is $ARGV[1]\n";
open BASE_INPUT, "<", "$ARGV[1]" or die "Couldn't open $!";
$inputfile = do { local $/; <BASE_INPUT> };
close BASE_INPUT;

open BASE_INPUT, "<", "$ARGV[1]" or die "Couldn't open $!";
while(<BASE_INPUT>) 
{
	if (/\s+celldm\(1\)\s*=\s+(\d+.\d+)/) {$celldm1old=$1}
	if (/\s+celldm\(2\)\s*=\s+(\d+.\d+)/) {$celldm2old=$1}
	if (/\s+celldm\(3\)\s*=\s+(\d+.\d+)/) {$celldm3old=$1}
	if (/\s+celldm\(4\)\s*=\s+(\d+.\d+)/) {$celldm4old=$1}
	if (/\s+celldm\(5\)\s*=\s+(\d+.\d+)/) {$celldm5old=$1}
	if (/\s+celldm\(6\)\s*=\s+(\d+.\d+)/) {$celldm6old=$1}
}
#Stores lattice vectors to a 3x3 piddle
#print $alat;

foreach (@positions_raw) 
{
	if (/^\s?\w+\s+\-?\d\.\d+/) {push @positions, $_}
}

#print @positions;
if(@crystal_axes_raw) 
{
		foreach (@crystal_axes_raw)
		{
			if (/\s+(-?\d.\d+\s+-?\d.\d+\s+-?\d.\d+)\s+/) 
			{my $tmp=pdl($1);		
			$crystal_cell=$crystal_cell->glue(1,$tmp)
			}
		}

	$crystal_cell=$crystal_cell->slice(":,1:3");
	print $crystal_cell;
	#print $alat;
	$crystal_cell=$crystal_cell*$alat;


	my $dim1=$crystal_cell->slice(":,0");
	my $dim2=$crystal_cell->slice(":,1");
	my $dim3=$crystal_cell->slice(":,2");

	$celldm1=sclr(sqrt($dim1 x transpose($dim1)));
	$celldm2=sclr(sqrt($dim2 x transpose($dim2))/$celldm1);
	$celldm3=sclr(sqrt($dim3 x transpose($dim3))/$celldm1);
	$celldm4=sclr(($dim3 x transpose($dim2))/($celldm2*$celldm3*($celldm1**2) ));
	$celldm5=sclr(($dim3 x transpose($dim1))/($celldm3*$celldm1));
	$celldm6=sclr(($dim2 x transpose($dim1))/($celldm2 * $celldm1*$celldm1));

	###Calculates celldms and edits input file

	#$test = $dim1 * $dim1;
	if ($verbose)
    {
        print "celldm(1) =  $celldm1\n";
        print "celldm(2) =  $celldm2\n";
        print "celldm(3) =  $celldm3\n";
        unless(abs($celldm4) < 0.01) {print "celldm(4) =  $celldm4\ncelldm(5) =  $celldm5\ncelldm(6) = $celldm6\n";
    }
}

#print $crystal_cell;
}


#print $dim1;
#print sqrt($dim1 x transpose($dim1));
#print sqrt($dim2 x transpose($dim2));
#print sqrt($dim3 x transpose($dim3));
#print @positions_raw;



###End Block1



$temp_input=$inputfile;
			#print "The input is $inputfile\n";
$temp_input=~ s/ATOMIC_POSITIONS\s*{crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n@positions\nK_POINTS AUTOMATIC/sg;

if(@crystal_axes_raw)
{
	$temp_input=~ s/$celldm1old/$celldm1/;
	$temp_input=~ s/$celldm2old/$celldm2/;
	$temp_input=~ s/$celldm3old/$celldm3/;
	if($celldm4old) 
    {
        {$temp_input=~ s/$celldm4old/$celldm4/;}
        {$temp_input=~ s/$celldm5old/$celldm5/;}
        {$temp_input=~ s/$celldm6old/$celldm6/;}
    }else{
        unless(abs($celldm4) < 0.01)
    	{
        $temp_input=~ s/$celldm3,\n/$celldm3,\n  celldm(4) = $celldm4,\n  celldm(5) = $celldm5,\n  celldm(6) = $celldm6,\n/;
        $temp_input=~ s/\n\s*ibrav\s+=\s*\d+\s*,/\n  ibrav       = 14,/
        }

    }
}
open OUTPUT, ">", "next.pbs";
print OUTPUT $temp_input;
close OUTPUT;


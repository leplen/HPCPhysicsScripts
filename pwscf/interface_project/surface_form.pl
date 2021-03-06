#!/usr/bin/perl

#This script is intended to take a base pwscf input file and create input files
#appropriate for determining the minimum energy cleavage plane. More notes can be found at the bottom

use PDL;
#use strict;
use PDL::NiceSlice;
use PDL::Basic;

my $verbose=1; #set to true for debug messages, set to false for normal operation

if ($verbose) {use warnings;}

if (@ARGV<1) 	{die "Error. This script requires commandline arguments: Vac%, direction, fractional origin shift e.g.:\n cleave_planes.pl 0.20 x 0.11\n";}

my $VAC_percent=($ARGV[0]);

#Declare global variables
my $celldm1;
my $celldm2;
my $celldm3;
my $atom_pos=pdl;
my @atom_list;
my $inputfile;
#BEGIN DATA READ
{
#Declare read variables
my @positions_raw; 
my @positions;



#Reads whole file into scalar inputfile. This will serve as basis later on
open BASE_INPUT, "<", "base_input.pbs" or die "Requires a file called base_input.pbs";
$inputfile = do { local $/; <BASE_INPUT> };
close BASE_INPUT;

#Reads positions, lattice constants, and atomic labels
open BASE_INPUT, "<", "base_input.pbs" or die "Couldn't open $!";
while(<BASE_INPUT>) 
{
	if (/\s*celldm\(1\)\s*=\s+(\d+.\d+)/) {$celldm1=$1}
	if (/\s*celldm\(2\)\s*=\s+(\d+.\d+)/) {$celldm2=$1}
	if (/\s*celldm\(3\)\s*=\s+(\d+.\d+)/) {$celldm3=$1}
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions_raw,$_;}
}
close BASE_INPUT;

#Strips out lines that don't contain coordinates since matching above is too inclusive
foreach(@positions_raw) {
	~ s/\s.*e-.*\s/ 0 /;
	~ s/\s0\s/ 0.00 /}
foreach (@positions_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @positions, $_} }
foreach(@positions_raw) {}
#Save atomic labels and orders to atom list
foreach (@positions) {/(\w+)/g; push(@atom_list, $1); }

#Save positions to @positions, and make all positions between 0 and 1
foreach (@positions) {~ s/\s*\w+\s+//}    
foreach (@positions) {if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}}

#Save positions to matrix $atom_pos
my $num_atoms;
foreach (@positions) 
	{my $temp=pdl($_);
	$atom_pos=$atom_pos->glue(1,$temp);
	$num_atoms++; 
	}
$atom_pos=$atom_pos->slice(":,1:$num_atoms");

my $printtemp=$VAC_percent * $celldm1;
print "Vacuum region is $printtemp\n";
} ##END READ
my $coord=$ARGV[1];

my @final_coord=();
$cell1_final;
$cell2_final;
$cell3_final;
if ($coord eq "x" )
{	$VAC_percent++;
	my $celldm1_x=$VAC_percent*$celldm1;
	my $celldm2_x=$celldm2/$VAC_percent;
	my $celldm3_x=$celldm3/$VAC_percent;
	my $x_transform=pdl([1/$VAC_percent,1,1]);
	for (my $i=0;$i<$size;$i++) 
	{
		my $check_value=at($atom_pos,0,$i);
		#print "Dir is $_\n";
		if ($check_value < ($ARGV[2]) ) 
		{
			set $shift, 0,$i,1;
		#	print "Dir is $_ and check value is $check_value and $i\n";
		}
	}
	my $size=$atom_pos->getdim(1);
	my $shift=zeroes(3,$size);

	

	my $atom_pos_x=($atom_pos+$shift)*$x_transform;	
	
	for(my $i=0;$i<@atom_list;$i++) 
	{
		my $coordinates=$atom_pos_x->slice(":,$i");
		$final_coord[$i]="$atom_list[$i]"."$coordinates";
	}
	$cell1_final=$celldm1_x;
	$cell2_final=$celldm2_x;
	$cell3_final=$celldm3_x;
}elsif ($coord eq "y" ){
	my $celldm2_y=$celldm2+$VAC_percent;
	my $y_transform=pdl([1,($celldm2/$celldm2_y),1]);

	my $size=$atom_pos->getdim(1);
	my $shift=zeroes(3,$size);
			
	for (my $i=0;$i<$size;$i++) 
	{
		my $check_value=at($atom_pos,1,$i);
		if ($check_value< ($ARGV[2]) ) 
		{
			set $shift, 1,$i,1;
		}
	}
	my $atom_pos_y=($atom_pos+$shift)*$y_transform;
	for(my $i=0;$i<@atom_list;$i++) 
	{
		my $coordinates=$atom_pos_y->slice(":,$i");
		$final_coord[$i]="$atom_list[$i]"."$coordinates";
	} 
 
	$cell1_final=$celldm1;
	$cell2_final=$celldm2_y;
	$cell3_final=$celldm3;
}


system(mkdir "$coord"."_surface" );
foreach(@final_coord) {~ s/[\[|\]]//g }
foreach(@final_coord) {~ s/\s*\n//}
foreach(@final_coord) {~ s/\n//}
my $temp_input=$inputfile;
#print "The input is $inputfile\n";
$temp_input=~ s/ATOMIC_POSITIONS {crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n@final_coord\nK_POINTS AUTOMATIC/sg;
$temp_input=~ s/$celldm1/$cell1_final/;
$temp_input=~ s/$celldm2/$cell2_final/;
$temp_input=~ s/$celldm3/$cell3_final/;
open OUTPUT, ">", "$coord"."_surface"."/position_test.pbs";
print OUTPUT $temp_input;
close OUTPUT;


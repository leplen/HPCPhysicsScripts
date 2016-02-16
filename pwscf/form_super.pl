#!/usr/bin/perl

#This script is intended to take a base pwscf input file and create input files
#appropriate for determining the minimum energy cleavage plane. More notes can be found at the bottom

use PDL;
use strict;
use PDL::NiceSlice;
use PDL::Basic;

my $verbose=0; #set to true for debug messages, set to false for normal operation

if ($verbose) {use warnings;}

#Declare global variables
my $num_atoms;
my $celldm1;
my $celldm2;
my $celldm3;
my $atom_pos=pdl;
my @atom_list;
my $inputfile; 
my $x_mult=$ARGV[0];
my $y_mult=$ARGV[1];
my $z_mult=$ARGV[2];

my $inputfile_name;  #if multiple pbs files are present or .pbs file is not input, set this explictly to the filename
#print "Proper syntax is:\n form_super.pl 2 2 1\n";
###Identifying 
unless ($inputfile_name)
{
	if ($verbose) {print "Assuming *.pbs file is input file. Edit inputfile_name parameter to change\n";}
	my @pbsfiles;my $input_file;
	opendir(DIR,".") or die "opening directory failed:$!";  
	my @files=readdir(DIR);
	foreach(@files)
	{
		if($_=~/pbs$/) {push @pbsfiles, $_;}
	}
	closedir(DIR);
	$inputfile_name=$pbsfiles[0];
	if (@pbsfiles>1) {print "Multiple pbs files found.\n 
	Rename one or open this script and set the parameter $inputfile_name to the correct file name."; die;}
}


if (@ARGV<1) 	{print "Error. Proper syntax is:\n form_super.pl 2 2 1
For a 2a x 2b x c supercell. Please specify cell size.\n";}


#BEGIN DATA READ
{
#Declare read variables
my @positions_raw; 
my @positions;



#Reads whole file into scalar inputfile. This will serve as basis later on
open BASE_INPUT, "<", "$inputfile_name" or die "Couldn't open $!";
$inputfile = do { local $/; <BASE_INPUT> };
close BASE_INPUT;

#Reads positions, lattice constants, and atomic labels
open BASE_INPUT, "<", "$inputfile_name" or die "Couldn't open $!";
while(<BASE_INPUT>) 
{
	if (/\s+celldm\(1\)\s*=\s+(\d+.\d+)/) {$celldm1=$1}
	if (/\s+celldm\(2\)\s*=\s+(\d+.\d+)/) {$celldm2=$1}
	if (/\s+celldm\(3\)\s*=\s+(\d+.\d+)/) {$celldm3=$1}
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions_raw,$_;}
}
close BASE_INPUT;

#Strips out lines that don't contain coordinates since matching above is too inclusive
foreach (@positions_raw) { if (/^\s?\w+\s+\-?\d\.\d+/) {push @positions, $_} }
@positions_raw=&pretty_pos(@positions_raw);
#Save atomic labels and orders to atom list
@atom_list=@positions;
foreach (@atom_list) {~ s/-?\d+.\d+//g }
#Save positions to @positions, and make all positions between 0 and 1
foreach (@positions) {~ s/(Li|P|O|S|Au|Na|Ge)\s+//}
#Save positions to matrix $atom_pos

foreach (@positions) 
	{my $temp=pdl($_);
	$atom_pos=$atom_pos->glue(1,$temp);
	$num_atoms++; 
	}
$atom_pos=$atom_pos->slice(":,1:$num_atoms");
} ##END READ

##BEGIN CALC AND WRITE

#Variables needed for printing
my $num_atoms_new=$num_atoms*$x_mult*$y_mult*$z_mult;
my @atom_list_new;
my $atom_pos_new=pdl;
my $celldm1_new=$celldm1*$x_mult;
my $celldm2_new=$celldm2*$y_mult/$x_mult;
my $celldm3_new=$celldm3*$z_mult/$x_mult;

#Making copies of the unit cell in reduced coordinates
{
for(my $i=0; $i<$x_mult*$y_mult*$z_mult; $i++)
{$atom_pos_new=$atom_pos_new->glue(1,$atom_pos)};


my $transform=pdl[[1/$x_mult,0,0],[0,1/$y_mult,0],[0,0,1/$z_mult] ];
$atom_pos_new=$atom_pos_new x $transform;
}
$atom_pos_new=$atom_pos_new->slice(":,1:$num_atoms_new");


#Shifting those copies
{
my $shift=pdl;
my $size=$num_atoms;
my $one_col=ones(1,$size);

for(my $xs=0; $xs<$x_mult; $xs++)
{
	my $xshift=($xs/$x_mult)*$one_col;
	
	for(my $ys=0; $ys<$y_mult; $ys++)
	{
	my $yshift=	($ys/$y_mult)*$one_col;
	
		for(my $zs=0; $zs<$z_mult; $zs++)
		{
		my $zshift=($zs/$z_mult)*$one_col;
		my $temp_shift=$xshift->glue(0, $yshift,$zshift); #transpose stuff is weird, but makes formatting come out clearly
	#	$temp_shift=transpose($temp_shift);
		$shift = $shift->glue(1,$temp_shift);
		}
	}
}
$shift=$shift->slice(":,1:$num_atoms_new");
#my $dim0 = $atom_pos_new->getdim(1);
#print $dim0;
$atom_pos_new=$atom_pos_new+$shift;
}
for(my $i=0;$i<$x_mult*$y_mult*$z_mult;$i++) {push(@atom_list_new,@atom_list)};

my @final_coord;
for(my $i=0;$i<@atom_list_new;$i++) 
{
	my $coordinates=$atom_pos_new->slice(":,$i");
	$final_coord[$i]="$atom_list_new[$i]"."$coordinates";
}
foreach(@final_coord) {~ s/[\[|\]]/ /g }
foreach(@final_coord) {~ s/\s*\n//}
foreach(@final_coord) {~ s/\n//}
@final_coord=&pretty_pos(@final_coord);
my $temp_input=$inputfile;
#print "The input is $inputfile\n";
$temp_input=~ s/ATOMIC_POSITIONS {crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n@final_coord\nK_POINTS AUTOMATIC/sg;
$temp_input=~ s/\s+nat\s+=\s*$num_atoms/\n  nat         = $num_atoms_new/;
$temp_input=~ s/$celldm1/$celldm1_new/;
$temp_input=~ s/$celldm2/$celldm2_new/;
$temp_input=~ s/$celldm3/$celldm3_new/;
open OUTPUT, ">", "supercell.pbs";
print OUTPUT $temp_input;
close OUTPUT;
#system("cd x_"."$_".";qsub position_test.pbs"); 


 #END CALC AND WRITE

sub pretty_pos
{
    foreach (@_)
    {
    ~ s/\S*e-\d+/ 0 /g;
    if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}
    if (/\s1\./) {~ s/(\s1\.)/\t0./g}
    ~ s/\s0\s/ 0.00 /g;
    ~ s/\s0\s/ 0.00 /g;
    ~ s/\s0\s/ 0.00 /g;
    if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
    {$_=sprintf( "%s\t%.8f %.8f %.8f\n" , $1, $2, $3, $4 )}
    }
    return @_;
}






=head

Program Notes:

Currently set up for Li3PO4, which is orthorhombic (i.e. a regtangular prism w/ v1=(a,0,0) v2=(0,b,0) vc=(0,0,c) ).
The system used for modifying the fractional coordinates may not work with lower symmetry structures.

Program Outline: 

Read lc, atomic symbol list and positions from input file
Store each celldm to its own variable
Store positions to a pdl (matrix data type).

Treat x,y and z separately b/c of celldm

Foreach (x,y,z)
#Need to add vacuum
	modify celldm  
	modify atom_post
	modify k-points

mkdirs x_1...x_10

Foreach (dir)
mod positions so different plane is exposed.

#!/usr/bin/perl

#This script is intended to take a base pwscf input file and create input files
#appropriate for determining the minimum energy cleavage plane. More notes can be found at the bottom

use PDL;
use strict;
use PDL::NiceSlice;
use PDL::Basic;

my $verbose=1; #set to true for debug messages, set to false for normal operation

if ($verbose) {use warnings;}

if (@ARGV<1) 	{die "Error. This script requires the vacuum percentage as a commandline argument. e.g.:\n cleave_planes.pl 2\n";}

#Set vacuum percentage
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
my $inputfile_name; #if multiple pbs files are present, set this equal to the input name.
#my $inputfile_name="next.pbs"; 
unless ($inputfile_name)
{
#    if ($verbose) {print "Assuming *.pbs file is input file. Edit inputfile_name parameter to change\n";}
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
    if ($verbose) {print "Assuming $inputfile_name is input file. Edit inputfile_name parameter to change\n";}
}

#Reads whole file into scalar inputfile. This will serve as basis later on
open BASE_INPUT, "<", "$inputfile_name" or die "Requires a file called base_input.pbs";
$inputfile = do { local $/; <BASE_INPUT> };
close BASE_INPUT;

#Reads positions, lattice constants, and atomic labels
open BASE_INPUT, "<", "$inputfile_name" or die "Couldn't open $!";
while(<BASE_INPUT>) 
{
	if (/\s*celldm\(1\)\s*=\s+(\d+.\d+)/) {$celldm1=$1}
	if (/\s*celldm\(2\)\s*=\s+(\d+.\d+)/) {$celldm2=$1}
	if (/\s*celldm\(3\)\s*=\s+(\d+.\d+)/) {$celldm3=$1}
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions_raw,$_;}
}
close BASE_INPUT;

unless(@positions_raw) {die "Atoms not found\n"}
#Strips out lines that don't contain coordinates since matching above is too inclusive
foreach(@positions_raw) {
	~ s/\s.*e-.*\s/ 0 /;
	~ s/\s0\s/ 0.00 /}
foreach (@positions_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @positions, $_} }
#foreach(@positions_raw) {}
#Save atomic labels and orders to atom list
foreach (@positions) {/(\w+)/g; push(@atom_list, $1); }

#Save positions to @positions, and make all positions between 0 and 1
foreach (@positions) {~ s/\s*\w+\s+//}    
foreach (@positions) {if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}}
unless(@positions) {die "Atom matching failed\n"}
#print @positions;

#Save positions to matrix $atom_pos
my $num_atoms;
foreach (@positions) 
	{my $temp=pdl($_);
	$atom_pos=$atom_pos->glue(1,$temp);
	$num_atoms++; 
	}
$atom_pos=$atom_pos->slice(":,1:$num_atoms");

print "Vacuum region is ".$VAC_percent*$celldm1."\n";
} ##END READ



#BEGIN CALC & WRITE
{

my $slices=10; #the number of cleaves you want to attempt
my @dir;
for (my $i=0;$i<$slices;$i++) 
{
	$dir[$i]=sprintf("%02s", $i);
}

#my @coord= ("x", "y", "z");
#my @coord= ('y');
my @coord= ('y');

foreach(@coord) 
{
	if ($_ eq "x" )
	{	$VAC_percent++;
		my $celldm1_x=$VAC_percent*$celldm1;
		my $celldm2_x=$celldm2/$VAC_percent;
		my $celldm3_x=$celldm3/$VAC_percent;
		my $x_transform=pdl([1/$VAC_percent,1,1]);
		
	
		foreach(@dir)
		{
			my @final_coord=();
			my $size=$atom_pos->getdim(1);
			my $shift=zeroes(3,$size);
			
			#print  "x"."$_"
			system(mkdir "x_"."$_" );
			for (my $i=0;$i<$size;$i++) 
			{
				my $check_value=at($atom_pos,0,$i);
				#print "Dir is $_\n";
				if ($check_value< ($_*0.1) ) 
				{
					set $shift, 0,$i,1;
				#	print "Dir is $_ and check value is $check_value and $i\n";
				}
			}
				#print "$size and $check_value\n";
			my $atom_pos_x=($atom_pos+$shift)*$x_transform;
			#print $atom_pos_x;
			
			
			for(my $i=0;$i<@atom_list;$i++) 
			{
				my $coordinates=$atom_pos_x->slice(":,$i");
				$final_coord[$i]=$atom_list[$i]."$coordinates ";
			}
			foreach(@final_coord) {~ s/[\[|\]]//g }
			foreach(@final_coord) {~ s/\s*\n//}
			foreach(@final_coord) {~ s/\n//}
            @final_coord=&pretty_pos(@final_coord);
			my $temp_input=$inputfile;
			#print "The input is $inputfile\n";
			$temp_input=~ s/ATOMIC_POSITIONS {crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n@final_coord\nK_POINTS AUTOMATIC/sg;
			$temp_input=~ s/$celldm1/$celldm1_x/; #probably should be redone in the style below, can get weird matches is celldm numbers are whole numbers
			$temp_input=~ s/$celldm2/$celldm2_x/;
			$temp_input=~ s/$celldm3/$celldm3_x/;
			open OUTPUT, ">", "x_"."$_"."/position_test.pbs";
			print OUTPUT $temp_input;
			close OUTPUT;
			#system("cd x_"."$_".";qsub position_test.pbs"); 
		}#end foreach
	}#endif
	elsif ($_ eq "y" )
	{
		my $celldm2_y=$celldm2+$VAC_percent;
		my $y_transform=pdl([1,($celldm2/$celldm2_y),1]);
		
	
		foreach(@dir)
		{
			my @final_coord=();
			my $size=$atom_pos->getdim(1);
			my $shift=zeroes(3,$size);
			
			system(mkdir "y_"."$_" );
			for (my $i=0;$i<$size;$i++) 
			{
				my $check_value=at($atom_pos,1,$i);
				if ($check_value< ($_*0.1) ) 
				{
					set $shift, 1,$i,1;
				}
			}
			my $atom_pos_y=($atom_pos+$shift)*$y_transform;
			
			
			for(my $i=0;$i<@atom_list;$i++) 
			{
				my $coordinates=$atom_pos_y->slice(":,$i");
				$final_coord[$i]=$atom_list[$i]."$coordinates ";
			}
			foreach(@final_coord) {~ s/[\[|\]]//g }
			foreach(@final_coord) {~ s/\s*\n//}
			foreach(@final_coord) {~ s/\n//}
            @final_coord=&pretty_pos(@final_coord);
			my $temp_input=$inputfile;
			$temp_input=~ s/ATOMIC_POSITIONS.*{crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n@final_coord\nK_POINTS AUTOMATIC/sg;
			$temp_input=~ s/celldm\(2\)\s*=\s*$celldm2/celldm(2)  =  $celldm2_y/;
			open OUTPUT, ">", "y_"."$_"."/position_test.pbs";
			print OUTPUT $temp_input;
			close OUTPUT;
			#system("cd y_"."$_".";qsub position_test.pbs"); 
		}
	} #end elsif
	elsif ($_ eq "z" )
	{
		my $celldm3_z=$celldm3+$VAC_percent;
		my $z_transform=pdl([1,1,($celldm3/$celldm3_z)]);
		
	
		foreach(@dir)
		{
			my @final_coord=();
			my $size=$atom_pos->getdim(1);
			my $shift=zeroes(3,$size);
			
			system(mkdir "z_"."$_" );
			for (my $i=0;$i<$size;$i++) 
			{
				my $check_value=at($atom_pos,2,$i);
				if ($check_value< ($_*0.1) ) 
				{
					set $shift, 2,$i,1;
				}
			}
			my $atom_pos_z=($atom_pos+$shift)*$z_transform;
			
			
			for(my $i=0;$i<@atom_list;$i++) 
			{
				my $coordinates=$atom_pos_z->slice(":,$i");
				$final_coord[$i]=$atom_list[$i]."$coordinates";
			}
			foreach(@final_coord) {~ s/[\[|\]]//g }
			foreach(@final_coord) {~ s/\s*\n//}
			foreach(@final_coord) {~ s/\n//}
            @final_coord=&pretty_pos(@final_coord);
			my $temp_input=$inputfile;
			$temp_input=~ s/ATOMIC_POSITIONS {crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n@final_coord\nK_POINTS AUTOMATIC/sg;
			$temp_input=~ s/celldm\(3\)\s*=\s*$celldm3/celldm(3)  =  $celldm3_z/;
			open OUTPUT, ">", "z_"."$_"."/position_test.pbs";
			print OUTPUT $temp_input;
			close OUTPUT;
			#system("cd z_"."$_".";qsub position_test.pbs"); 
		}
	}
}

} #END CALC AND WRITE


sub pretty_pos
{
    foreach (@_)
    {
    ~ s/\s.*e-.*\s/ 0 /g;
    if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}
    if (/\s1\./) {~ s/(\s1\.)/\t0./g}
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

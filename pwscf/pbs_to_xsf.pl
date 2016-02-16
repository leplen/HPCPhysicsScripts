#!/usr/bin/perl

#takes the pbs file as an optional input 
#(will just find the .pbs file in the directory if not given an input and creates an XSF file called PBS.xsf
#
#N.Lepley 5/2012
#
#This borrows from many of my other scripts, and I try to use PDL (matlab like matrix data types) to simplify the linear algebra as much as possible

#use warnings;
use PDL;
use PDL::Math;
#use Math::Trig;
use strict;
use PDL::NiceSlice;
use PDL::Basic;

#Declare globals
my $ibrav;
my $celldm1;my $celldm2;my $celldm3;my $celldm4;my $celldm5;my $celldm6;
my @positions_raw; my @positions; my @atom_list; my $atom_pos=pdl; my $crystal_cell=pdl;

#Read operation
{
	my @pbsfiles;my $input_file;
	if (@ARGV<1) 
	{
		
		opendir(DIR,".") or die "opening directory failed:$!";  
		my @files=readdir(DIR);
		foreach(@files)
		{
			if($_=~/pbs$/) {push @pbsfiles, $_;}
		}
		closedir(DIR);
		$input_file=$pbsfiles[0];
		if (@pbsfiles>1) {print "Multiple pbs files found.\n Give the one you want as a commandline argument."; die;}
	}
	else
	{$input_file=$ARGV[0];}
	open (PBSFILE, "<", "$input_file") or die "Can't find $input_file!" ;
}

while(<PBSFILE>)
{
	if (/ibrav\s*=\s*(\d+)/) {$ibrav=$1;}
	if (/\s*celldm\(1\)\s*=\s+(\d+.\d+)/) {$celldm1=$1}
	if (/\s*celldm\(2\)\s*=\s+(\d+.\d+)/) {$celldm2=$1}
	if (/\s*celldm\(3\)\s*=\s*(\d),/) {$celldm3=$1} #in case celldm3 has one digit of accuracy
	if (/\s*celldm\(3\)\s*=\s+(\d+.\d+)/) {$celldm3=$1}
	if (/\s*celldm\(4\)\s*=\s+(-?\d+.\d+)/) {$celldm4=$1}
	if (/\s*celldm\(5\)\s*=\s+(-?\d+.\d+)/) {$celldm5=$1}
	if (/\s*celldm\(6\)\s*=\s+(-?\d+.\d+)/) {$celldm6=$1}
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions_raw,$_;}
}

close PBSFILE;
#print $celldm1;
#print @positions_raw;
################################################################################################
##### Processing Input for Atomics Positions #################################           #######

#Removes coordinates of the form 9.61e-08, replaces with zero
foreach(@positions_raw) {~ s/\s.*e-.*\s/ 0 /}
foreach(@positions_raw) {~ s/\s0\s/ 0.00 /g}

#Strips out lines that don't contain coordinates since matching above is too inclusive      ###
foreach (@positions_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @positions, $_} }                ##
#Save atomic labels and order to atom list                                                    ##
foreach (@positions) {/(\w+)/g; push(@atom_list, $1); }
#Save just numerical positions to @positions, and make all positions between 0 and 1           ##
foreach (@positions) {~ s/\s*\w+\s+//}    
#foreach (@positions) {if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}}                         ####
#Save positions to matrix(pdl) $atom_pos                                                      ##
my $num_atoms;                                                                               ###
foreach (@positions)                                                                        ####
	{
	my $temp=pdl($_);                                                                   ####
	$atom_pos=$atom_pos->glue(1,$temp);                                                 ####
	$num_atoms++; 
	}                                                                                     ##
$atom_pos=$atom_pos->slice(":,1:$num_atoms");                                              #####
################################################################################################

#print @positions;
####Processing input for crystal cell
my $v1; my $v2; my $v3;
$celldm1=$celldm1*0.529177249;
if($ibrav==1)  {$v1=$celldm1*pdl[1,0,0];$v2=$celldm1*pdl[0,1,0];$v3=$celldm1*pdl[0,0,1];} #Simple cubic (P) 
elsif($ibrav==2)  {$v1=$celldm1/2*pdl[-1,0,1];$v2=$celldm1/2*pdl[0,1,1];$v3=$celldm1/2*pdl[-1,1,0];} #FCC (F)
elsif($ibrav==3)  {$v1=$celldm1/2*pdl[1,1,1];$v2=$celldm1/2*pdl[-1,1,1];$v3=$celldm1/2*pdl[-1,-1,1];} #BCC (I)
elsif($ibrav==4)  {$v1=$celldm1*pdl[1,0,0];$v2=$celldm1*pdl[-1/2,sqrt(3)/2,0];$v3=$celldm1*pdl[0,0,$celldm3];} #Hexagonal and trigonal (P)
elsif($ibrav==5)  {$v1=$celldm1*pdl[sqrt((1-$celldm4)/2),-sqrt((1-$celldm4)/6),sqrt((1+2*$celldm4)/3)];$v2=$celldm1*pdl[0,2*sqrt((1-$celldm4)/6),sqrt((1+2*$celldm4)/3)];$v3=$celldm1*pdl[-sqrt((1-$celldm4)/2),-sqrt((1-$celldm4)/6),sqrt((1+2*$celldm4)/3) ];} #trigonal 
elsif($ibrav==6)  {$v1=$celldm1*pdl[1,0,0];$v2=$celldm1*pdl[0,1,0];$v3=$celldm1*pdl[0,0,$celldm3];} #tetragonal (P)
elsif($ibrav==7)  {$v1=$celldm1/2*pdl[1,-1,$celldm3];$v2=$celldm1/2*pdl[1,1,$celldm3];$v3=$celldm1/2*pdl[-1,-1,$celldm3];} #Body centered tetragonal (I)
elsif($ibrav==8)  {$v1=$celldm1*pdl[1,0,0];$v2=$celldm1*pdl[0,$celldm2,0];$v3=$celldm1*pdl[0,0,$celldm3];} #orthorhombic (p)
elsif($ibrav==9)  {$v1=$celldm1/2*pdl[1,$celldm2,0];$v2=$celldm1/2*pdl[-1,$celldm2,0];$v3=$celldm1*pdl[0,0,$celldm3];} #Base centered orthorhombic
elsif($ibrav==10)  {$v1=$celldm1/2*pdl[1,0,$celldm3];$v2=$celldm1/2*pdl[1,$celldm2,0];$v3=$celldm1/2*pdl[0,$celldm2,$celldm3];}#face centered orthorhombic
elsif($ibrav==11) {$v1=$celldm1/2*pdl[1,$celldm2,$celldm3];$v2=$celldm1/2*pdl[-1,$celldm2,$celldm3];$v3=$celldm1/2*pdl[-1,-$celldm2,$celldm3];} #body centered orthorhombic
elsif($ibrav==12)  {$v1=$celldm1*pdl[1,0,0];$v2=$celldm1*pdl[$celldm2*$celldm4,$celldm2*sin(acos($celldm4)),0];$v3=$celldm1*pdl[0,0,$celldm3];} #monoclinic (P) 
elsif($ibrav==13)  {$v1=$celldm1*pdl[1/2,0,-$celldm3/2];$v2=$celldm1*pdl[$celldm2*$celldm4,$celldm2*sin(acos($celldm4)),0];$v3=$celldm1/2*pdl[1,0,$celldm3];} #base centered monoclinic
elsif($ibrav==14)   {$v1=$celldm1*pdl[1,0,0];
$v2=$celldm1*pdl[$celldm2*$celldm6,$celldm2*sin(acos($celldm6)),0];

$v3=$celldm1*pdl[$celldm3*$celldm5,$celldm3/sin(acos($celldm6))*($celldm4-$celldm5*$celldm6),$celldm3*sqrt(1+2*$celldm4*$celldm5*$celldm6-$celldm4**2-$celldm5**2-$celldm6**2)*1/sin(acos($celldm6))];} #trigonal (#)

$crystal_cell = $v1->glue(1,$v2,$v3);

#print $crystal_cell;

###################################################


####Creating Output#######
my @final_coord; my $crystal_cell_clean; my $atom_pos_real;

$crystal_cell_clean=sprintf($crystal_cell);
$crystal_cell_clean=~ s/[\[|\]]//g;
$crystal_cell_clean=~ s/^\n*//g;
$crystal_cell_clean=~ s/\n*$//g;

$atom_pos_real=$atom_pos x $crystal_cell;

#print $atom_pos_real;
for(my $i=0;$i<@atom_list;$i++) 
	{
	my $coordinates=$atom_pos_real->slice(":,$i");
	$final_coord[$i]="$atom_list[$i]"."$coordinates";
	}
	
#print @final_coord;
foreach(@final_coord) {~ s/[\[|\]]//g }
foreach(@final_coord) {~ s/\s*\n//}
foreach(@final_coord) {~ s/\n//}

##printing

open OUTPUT, ">", "pbs.xsf";
printf OUTPUT "CRYSTAL\nPRIMVEC
$crystal_cell_clean
PRIMCOORD 1
$num_atoms 1
@final_coord";
close OUTPUT;

##arccos subroutine

#sub acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }

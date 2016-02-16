#!/usr/bin/perl

#use warnings;
use PDL;
#use strict;
use PDL::NiceSlice;
use PDL::Basic;

open INPUT, "<", "$ARGV[0]" or print "Couldn't open $!";
open OUTPUT, "<", "$ARGV[1]" or print "Couldn't open $!";

print "Input is $ARGV[0]. Output is $ARGV[1]\n";
my @final_positions_raw;
my @final_positions;
my $final_atom_pos=pdl;

while(<OUTPUT>) 
{
	if (/Begin final coordinates/ .. /End final coordinates/) {push @final_positions_raw,$_;}
}

#print @final_positions_raw;
################################################################################################
##### Processing Output for Atomics Positions #################################           #######
                                                                                           ####
#Strips out lines that don't contain coordinates since matching above is too inclusive      ###
foreach(@final_positions_raw) {~ s/\s0\s/ 0.00 /}
#Removes coordinates of the form 9.61e-08, replaces with zero
foreach(@final_positions_raw) {~ s/\s.*e-.*\s/ 0 /}
foreach (@final_positions_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @final_positions, $_} }                ##
#Save atomic labels and order to atom list                                                    ##

foreach (@final_positions) {~ s/\s*\w+\s+//}    
my $num_atoms;                                                                               ###
foreach (@final_positions)                                                                        ####
	{
	my $temp=pdl($_);                                                                   ####
	$final_atom_pos=$final_atom_pos->glue(1,$temp);                                                 ####
	$num_atoms++; 
	}             
#print $num_atoms;                                                                        ##
$final_atom_pos=$final_atom_pos->slice(":,1:$num_atoms");                                              #####
################################################################################################
#print $final_atom_pos;
my $alat;
my @crystal_axes_raw;
my $atom_pos=pdl;
while(<INPUT>)
{
	if (/ibrav\s*=\s*(\d+)/) {$ibrav=$1;}
	if (/\s*celldm\(1\)\s*=\s+(\d+.\d+)/) {$celldm1=$1}
	if (/\s*celldm\(2\)\s*=\s+(\d+.\d+)/) {$celldm2=$1}
	if (/\s*celldm\(3\)\s*=\s+(\d+.\d+)/) {$celldm3=$1}
	if (/\s*celldm\(4\)\s*=\s+(-?\d+.\d+)/) {$celldm4=$1}
	if (/\s*celldm\(5\)\s*=\s+(-?\d+.\d+)/) {$celldm5=$1}
	if (/\s*celldm\(6\)\s*=\s+(-?\d+.\d+)/) {$celldm6=$1}
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions_raw,$_;}
}
close INPUT;

#print @positions_raw;
################################################################################################
##### Processing Input for Atomics Positions #################################           #######
                                                                                            ####
#Strips out lines that don't contain coordinates since matching above is too inclusive      ###
foreach(@positions_raw) {~ s/\s0\s/ 0.00 /}
#Removes coordinates of the form 9.61e-08, replaces with zero
foreach(@positions_raw) {~ s/\s.*e-.*\s/ 0 /}
foreach (@positions_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @positions, $_} }                ##
#Save atomic labels and order to atom list                                                    ##
foreach (@positions) {/(\w+)/g; push(@atom_list, $1); }
#print @atom_list;
#Save just numerica positions to @positions, and make all positions between 0 and 1           ##
foreach (@positions) {~ s/\s*\w+\s+//}    
#print @positions;                                                       ##
#foreach (@positions) {if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}}                         ####
#Save positions to matrix(pdl) $atom_pos                                                      ##
foreach (@positions)                                                                        ####
	{
	my $temp=pdl($_);                                                                   ####
	$atom_pos=$atom_pos->glue(1,$temp);                                                 ####
	}                                                                                     ##
$atom_pos=$atom_pos->slice(":,1:$num_atoms");                                              #####
################################################################################################


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

##End Crystal cell
#print $atom_pos;
#print $final_atom_pos;
$distortion=$final_atom_pos-$atom_pos;
print "Distortion in crystal is\n";
print $distortion;
$distortion=$distortion x $crystal_cell;




#print $atom_pos_real;
for(my $i=0;$i<@atom_list;$i++) 
	{
	my $coordinates=$distortion->slice(":,$i");
	$final_coord[$i]="$atom_list[$i]"."$coordinates";
	}
	
#print @final_coord;
foreach(@final_coord) {~ s/[\[|\]]//g }
foreach(@final_coord) {~ s/\s*\n//}
foreach(@final_coord) {~ s/\n//}

##printing

print "Real space distortions are:\n";
print "@final_coord\n";

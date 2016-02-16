#!/usr/bin/perl
#
#
#use File::Glob

#my $xs=0.05;my $ys=0.0;my $zs=0.05; #define x-shift, y-shift, z-shift
my $xs=0.00;my $ys=0.05;my $zs=0; #define x-shift, y-shift, z-shift


my $Li_only=0; #set to true to only shift Li
$pc=6; #Li per cell
my @pos_raw; 
my @pos;


my @files=<*pbs>;

if (@files==1) {$filename=@files[0]} else {die "Multiple pbs files found.\n"}

open BASE_INPUT, "<", $filename or die "Requires a file called $filename\n";
$inputfile = do { local $/; <BASE_INPUT> };
close BASE_INPUT;

open INPUT, "<", $filename or die "Requires a file called $filename\n";
while(<INPUT>) 
{
	if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @pos_raw,$_;}
}
close INPUT;

foreach(@pos_raw) {~ s/\s0\n/ 0 \n/}
foreach(@pos_raw) {~ s/\s0\s/ 0.00 /g}
foreach (@pos_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push(@pos, $_) } }
foreach(@pos) {if(/P /){$pc++} } #count Phosphorous atoms
foreach(@pos) {~ s/^\s+//} 

if($Li_only){$Li_only=2} #Number of Li/formula unit
for(my $i=$Li_only*$pc;$i<@pos;$i++) #set to 8 to shift only Li, set to zero to shift all
{
    $pos[$i] =~ /^\s*(\w+)\s+(\-?\d+.\d+)\s+(\-?\d+.\d+)\s+(\-?\d+.\d+)/;
    #print "Old $pos[$i]";
    $x=$2;$y=$3;$z=$4;
    $xn=$x+$xs;
    $yn=$y+$ys;
    $zn=$z+$zs;
    if(($1 ne 'Li') and $Li_only) {warn "Error at position ".($i+1)."\n"}
    $pos[$i] =~ s/$x/$xn/;
    $pos[$i] =~ s/$y/$yn/;
    $pos[$i] =~ s/$z/$zn/;
    #print "New $pos[$i]";
}
foreach (@pos) #pretty pos sub routine.
{
    ~ s/\S*e-\S*/ 0 /;
    ~ s/\s0\s/ 0.00 /g;
    ~ s/^\s+//;
    if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}
    if (/\s1\./) {~ s/(\s1\.)/\t0./g}
    ~ s/\s0\s/ 0.0000 /g;
    if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
    {$_=sprintf( "%s\t%.8f  %.8f  %.8f\n" , $1, $2, $3, $4 )}
}

my $final_positions=join('',@pos);
my $temp_input=$inputfile;
$temp_input=~ s/ATOMIC_POSITIONS {crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n$final_positions\nK_POINTS AUTOMATIC/sg;
open OUTPUT, ">", "shifted.pbs";
print OUTPUT $temp_input;


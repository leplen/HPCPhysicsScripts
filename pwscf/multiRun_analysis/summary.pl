#!/usr/bin/perl

use Cwd;
#use warnings;
use strict;

my $resourceBOOL=0; #output resource usage
my $stepsBOOL=0; #output number of iterations
my $latticeBOOL=1; #output lattice information

#Finds all directories with a torque/pbs output file (e.g. Li3PO4.o818538) 
my @dirs;
if($ARGV[0] =~ /run/){@dirs=`find . -regex ".*\.o[0-9]+"`;} #can specify if "first_run dirs included"
else{@dirs=`find . -regex ".*\.o[0-9]+"|grep -v run|grep -v NEB|grep -v DOS`;}
my $cwd=getcwd;

#print "Dirs are @dirs";
#print "Current is $cwd\n";

foreach(@dirs) 
{
    reset;
    ~ s@[^/]*$@@; #gets directory name from full torque output filename (i.e. mydir/Li3P.o123->mydir)
    ~ s/\.//;
    my $tempdir=$cwd.$_;
    print "\nDirectory:$tempdir\n";
    my @files;
    chomp(@files=`find $tempdir -maxdepth 1 -type f`);
    ##Sorts list of files by extension, yields consistent print
    @files=sort {reverse($a) cmp reverse($b) }(@files);
    foreach my $filename (@files) 
    {
        open (FILE, "<", "$filename"); # or die "Can't find $filename!" ;
#INPUT file
        if($filename =~ /\.in$/)
        {
        #atom position variables
            my (@positions_raw, @positions, @atom_list, %counts, $keys, %enthalpies);
        #calc parameters
            my ($celldm1, $celldm2, $celldm3, $celldm4, $celldm5, $celldm6, $nat, $ecut, $calc, $axis, $charge,$kpoints);
            while(<FILE>)
            {
                if (/\s*celldm\(1\)\s*=\s+(\d+.\d{1,5})/) {$celldm1=$1}
                if (/\s*celldm\(2\)\s*=\s+(\d+.\d{1,5})/) {$celldm2=$1}
                if (/\s*celldm\(3\)\s*=\s+(\d+.\d{1,5})/) {$celldm3=$1}
                if (/\s*celldm\(4\)\s*=\s+(\d+.\d{1,5})/) {$celldm4=$1}
                if (/\s*celldm\(5\)\s*=\s+(\d+.\d{1,5})/) {$celldm5=$1}
                if (/\s*celldm\(6\)\s*=\s+(\d+.\d{1,5})/) {$celldm6=$1}

#                if (/\s*tot_charge\s*=\s*(-?\d+)/) {$charge=$1}else{$charge=0};
                if (/nat\s*=\s*(\d+)/) {$nat=$1;}
                if (/ecutwfc\s*=\s*(\d+)/) {$ecut=$1;}
                if (/calculation\s*=\s*["'](\w+-?\w+)/) {$calc=$1;}
                if (/cell_dofree\s*=\s*["'](\w+)/) {$axis=$1;}
                if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions_raw,$_;}
                if (/\s*(\d+\s+\d+\s+\d+)\s+\d+\s+\d+/) {$kpoints=$1;}
            }
            #if ($calc =~ /NEB/){next}
            foreach(@positions_raw) {~ s/\s0\s/ 0.00 /}
            foreach (@positions_raw) { if (/^\s*\w+\s+\-?\d\.\d+/) {push @positions, $_} }
            #Save atomic labels and order to atom list 
            foreach (@positions) {/(\w+)/; push(@atom_list, $1);}
            foreach (@atom_list) {$counts{$_}++;}
            print "Ecut is $ecut. Calculation is $calc. k-points are $kpoints. ";
            if ($calc =~ /vc/ && $axis =~ /[xyz]/) {print "cell_dofree is $axis.\n"}else{print "\n"}
            print "There are $nat atoms.\t";
            my $natcount=0; #checks that the # of atoms adds up to $nat
            my $Enthalpy=0; #prints the energy of the correct number of atoms in standard state
            if($ecut==49){%enthalpies=&Binding_En49}
            if($ecut==64){%enthalpies=&Binding_En64}
            foreach $keys (keys %counts)
            {
                $natcount=$natcount+$counts{$keys}; #checks that the # of atoms adds up to $nat
                $Enthalpy=$Enthalpy+$counts{$keys}*$enthalpies{$keys}; #Multiples # of atoms by ref. en for that atom and sums
                print "$keys:$counts{$keys}\t";
            }
            if($natcount!=$nat) {print "natcount is $natcount.\nAtom count off for $filename\n"}
            print "\nReference enthalpy: $Enthalpy";
#            print "\nCharge is $charge";
            print "\n";
            unless($calc =~ /vc/)
            {
                if($latticeBOOL && $celldm4){print "Input lattice: celldm1: $celldm1 celldm2: $celldm2",
                    " celldm3: $celldm3 celldm4: $celldm4 celldm5: $celldm5 celldm6: $celldm6\n";}
                elsif($latticeBOOL){print "Input lattice: celldm1: $celldm1 celldm2: $celldm2 celldm3: $celldm3\n";}
            }
        }
########OUTPUT file
        if($filename =~ /\.out$/)
        { 
            my $testtemp=`grep -a "new unit-cell volume" $filename|tail -n 1`; #see if lattice changes
            chomp($testtemp);
            if($testtemp) {print "Volume is $testtemp\n";}
            if($testtemp && $latticeBOOL) #finds output lattice constants
            {
                my @celldms;
                print "Output lattice: "; 
                my $alat= `grep -am 1 'alat' $filename`;
                $alat =~ m/(\d+\.\d+)/; $alat=$1;
                chomp(@celldms= `PWscf_triclinic $filename $alat|grep celldm`);
                { #begin scope for $celldmcounter
                my $celldmcounter=1;
                foreach(@celldms) 
                {
                    ~ /(\d+\.\d{5})/;
                    if($1>0.001){print "celldm$celldmcounter: $1  ";$celldmcounter++;}
                }
                } #end scope for celldmcounter if very local
                print "\n";
            }
            &energy_search($filename);
            if($stepsBOOL) {system("grep -a 'bfgs converged' $filename")}
        }

        if($filename =~ /\.o[0-9]+$/ && $resourceBOOL) {&resource_report($filename)} 
    }
}






sub energy_search
{
    my (@lines, $enlast, $ennotlast, $final_en, $finished);
    chomp(@lines=`fgrep -a "!   " "$_[0]" |tail`);
    chomp($final_en=`fgrep -a "Final en" "$_[0]"`);
    chomp($finished=`fgrep -a "Begin final coor" "$_[0]"`);
    $final_en =~ s/^\s+//;
    unless(@lines) {next};
    $lines[-1] =~m/(-\d+\.\d+)/;
    $enlast=$1;
    $lines[-2] =~m/(-\d+\.\d+)/;
    $ennotlast=$1;
    my $diff=$enlast-$ennotlast;
    if ($final_en) {print "$final_en\t Conv: $diff\n"} elsif ($finished)
    {print "Final en = $enlast  Conv: $diff\n"} else 
    {print "Current en: $enlast  Conv: $diff\n"};
} 


sub resource_report
{
    my $request=`grep "Resource Request:  cput" $_[0]`;
    my $consumed=`grep "Resource Consumed: cput" $_[0]`;
    chomp($consumed);
    chomp($request);
    my @rfields=split(',',$request);
    my @cfields=split(',',$consumed);

    foreach(@rfields) 
    {
        s/^.*=//;
        if(/mb/) 
        {
            $_=$_/1024;
        }
    }
    foreach(@cfields) 
    { 
        s/^.*=//;
        if(/kb/) 
        {
            s/kb//;
            $_=$_/1024/1024;
        }
    }
    print "Used\t\t\t\tRequested\nCPUtime:   $cfields[0]\t\tCPUtime:   $rfields[0]\nWalltime:   $cfields[3]\t\tWalltime:   $rfields[6]\nMem(GB):   $cfields[1]\tMem(GB):   $rfields[1]\nVmem(GB):   $cfields[2]\tpmem(GB):   $rfields[4]\n";

}
print "\n";

sub Binding_En49 #takes as an argument a hash with Atomic symbols as keys and counts as values
{
my ($Ry2eV, $Li,$P,$O,$N,$S,%Formation_en);
#Reference Energies (eV/atom) from heatofformation.m
$Ry2eV=13.60569193;
$Li=-201.62209454900201/$Ry2eV; #changed
$P =-722.4838317368841/$Ry2eV; #added 0.4073 eV/P to turn black-P into white-P
$S =-865.8311241080778/$Ry2eV; #changed
$N =-373.519689813/$Ry2eV; #not changed
$O =-551.686808904/$Ry2eV; # I didn't adjust the oxygen number since it was from a fit.

$Formation_en{ 'Li' }=$Li;
$Formation_en{ 'P' }=$P;
$Formation_en{ 'O' }=$O;
$Formation_en{ 'S' }=$S;
$Formation_en{ 'N' }=$N;
%Formation_en;
}

sub Binding_En64 #takes as an argument a hash with Atomic symbols as keys and counts as values
{
my ($Ry2eV, $Li,$P,$O,$N,$S,%Formation_en);
#Reference Energies (eV/atom) from heatofformation.m
$Ry2eV=13.60569193;
$Li=-201.622794970/$Ry2eV;
$P =-722.484462616/$Ry2eV;
$S =-865.831966985/$Ry2eV;
$N =-373.519689813/$Ry2eV;
$O =-551.686808904/$Ry2eV;

$Formation_en{ 'Li' }=$Li;
$Formation_en{ 'P' }=$P;
$Formation_en{ 'O' }=$O;
$Formation_en{ 'S' }=$S;
$Formation_en{ 'N' }=$N;
%Formation_en;
}


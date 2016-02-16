#!/usr/bin/perl
use 5.010; #provides say command

#$material=&MatEn('pnma-Li3PO4');
$material=&MatEn('Li2O');
$Number_of_cells=12;
#$Number_of_cells=2;


$Ryd2eV=13.605698066;
$Li_energy=-14.8190034;
@lines=`energy_search.pl Vac*/*out`;

if (1) { #set to zero to only run gnuplot fitting
open OUTPUT, '>', 'SurfaceEn.dat';
foreach(@lines)
{
    if( /Vac(\d).*EN:\s+(-\d+\.\d+).*e[-+]\d(\d)/)  #for matching vacuum calculations
    {
#        unless($3<5) #only uses converged results
        {
            $Vac_num=$1;
            $tot_en=$2;
            $tot_en-=$Number_of_cells*$material;
            $tot_en=$tot_en*$Ryd2eV;
            # $tot_en-=$Li_num*$Li_energy;
            print OUTPUT "$Vac_num\t$tot_en\n";
        }
    }
}

}
chomp($pwd=`pwd`);
$title= $pwd;   
$title =~ s!/!-!g;
$title =~ s!.*MoreInterface-!!;
open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
#open my $PROGRAM, '|-', 'less';

say {$PROGRAM} 'set offsets 0.0005, 0.0005, 0.0005, 0.0005 ';
say {$PROGRAM} "set title '$pwd'";
say {$PROGRAM} 'set key off';
say {$PROGRAM} "plot './SurfaceEn.dat' u 1:2 ps 3";
say {$PROGRAM} 'set terminal postscript color';
say {$PROGRAM} "set output 'Surf+$title.ps'";
say {$PROGRAM} "replot";


sub MatEn#Takes a compound as an argument and returns its energy in Ryd/Unit cell
{
my %Form_en;
$Form_en{ 'Pmn21-Li3PO4' }=-522.62355409;
$Form_en{ 'pnma-Li3PO4' }=-1045.23795252;
$Form_en{ 'Li2S' } = -93.5915510767;
$Form_en{ 'Li2O' } = -70.6347524881;
$Form_en{$_[0]};
}

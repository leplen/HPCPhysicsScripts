#!/usr/bin/perl
use 5.010; #provides say command

$material=&MatEn('Pmn21-Li3PO4');
#$material=&MatEn('Li2O');
#$material2=&MatEn('Li2S');
$Number_of_cells=3;
#$Number_of_cells2=8;
#$Number_of_cells=2;

$Ryd2eV=13.605698066;
$Li_energy=-14.8190034;
@lines=`energy_search.pl */*out`;

unless(@lines) {die "Matching failed\n"}
if (1) { #set to zero to only run gnuplot fitting
    open OUTPUT, '>', 'Sigma.dat';
    foreach(@lines)
    {
#        if( /3x(\d+).*EN:\s+(-\d+\.\d+).*e[-+]\d(\d)/)  #only matches directories of the form 3x#/ 
        if( /(\d+)Li.*EN:\s+(-\d+\.\d+).*e[-+]\d(\d)/)  #only matches directories of the form ##Li/ 
        {
#            unless($3<6) #only uses converged results
            {
                $Li_num=$1;
                $tot_en=$2;
                $tot_en-=$Number_of_cells*$material;
 #               $tot_en-=($Number_of_cells2*$Li_num-2)*$material2;
#                print "Number is ",$Number_of_cells2*$Li_num-2,"\n";
                $tot_en-=$Li_num*$Li_energy;
                $tot_en=$tot_en*$Ryd2eV;
                print OUTPUT "$Li_num\t$tot_en\n";
            }
        }
    }
}

if(1) {
    chomp($pwd=`pwd`);
    $title= $pwd;   
    $title =~ s!/!-!g;
    $title =~ s!.*MoreInterface-!!;

    #open my $PROGRAM, '|-', 'less' or die "Couldn't pipe to gnuplot: $!";
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";


    say {$PROGRAM} "f(x) =m*x+b";
    say {$PROGRAM} "fit f(x) 'Sigma.dat' u 1:2 via m, b";

    say {$PROGRAM} 'set nokey';
    say {$PROGRAM} 'set xrange[0:]';
    say {$PROGRAM} "set title '$pwd'";
    say {$PROGRAM} 'set ylabel "{/Symbol s}*A (eV)" ';
    say {$PROGRAM} 'set xlabel sprintf("m=%1.4f; b=%1.2f",m,b) ';
    say {$PROGRAM} "set terminal postscript color enhanced";
    say {$PROGRAM} "set output '$title.ps'";
    say {$PROGRAM} "plot './Sigma.dat' u 1:2 ps 3, f(x)";
    say {$PROGRAM} "set terminal x11";
    say {$PROGRAM} "replot";
}
sub MatEn#Takes a compound as an argument and returns its energy in Ryd/Unit cell
{
my %Form_en;
$Form_en{ 'Pmn21-Li3PO4' }=-522.62355409;
$Form_en{ 'pnma-Li3PO4' }=-1045.23795252;
$Form_en{ 'Pmn21-Li3PS4' }=-705.44766850;
#$Form_en{ 'pnma-Li3PO4' }=-1045.23795252;
$Form_en{ 'Li2S' } = -93.5915510767;
$Form_en{ 'Li2O' } = -70.6347524881;
$Form_en{$_[0]};
}

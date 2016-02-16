#!/usr/bin/perl

use 5.010; #provides the say command
#use warnings;
use Cwd;
#
#
my @dirs;
if($ARGV[0] && $ARGV[0] =~ /run/){@dirs=`find . -regex ".*\.o[0-9]+"`;} #can specify if "first_run dirs included"
else{@dirs=`find . -maxdepth 3 -regex ".*\.o[0-9]+"|grep -v run|grep DOS `;}
#else{@dirs=`find . -regex ".*\.o[0-9]+"|grep -v run|grep -v Test|grep -v old|grep -v reg`;}
#else{@dirs=`find . -regex ".*\.o[0-9]+"|grep DOS`;}
#else{@dirs=`find . -regex ".*\.o[0-9]+"|grep 'jitt\\|more'|grep -v 08|grep -v run`;}
my $cwd=getcwd;

foreach(@dirs)
{
    s![^/]*$!!; #gets directory name from full torque output filename (i.e. mydir/Li3P.o123->mydir)#!
    s/\.//;
    my $tempdir=$cwd.$_;
   # $tempdir=~ m/(\d\d)Li/;
    #$Li_num=$1;
   $lines=`tac $tempdir*.out|grep -A 200 "Fermi ener"|head -n 200|tac`; 
   # $lines=`grep -B 100 "Fermi ener" $tempdir*out`;
    $lines=~ s/^.*k(?!.*k)//s; #black lookahead magic http://www.perlmonks.org/?node_id=518444
    
    #Finds the difference between the system Fermi level and the lowest energy state
    if($lines=~ m/ev.*?(-\d+\.\d+)/s)
    {
        $energy_1s=$1;
        $lines=~ m/Fermi energy is\s+(-?\d+\.\d+)/;
        $fermiLevel=$1;
        $energy=$fermiLevel-$energy_1s;
        print "$tempdir:\t$energy\t$Li_num\n";
    }
    $lines =~ s/occup.*//s;
    $lines =~ s/^.*ev\)://s;
    @fields=split(/\s+/,$lines);
    for(my $i=0;$i<@fields;$i++)
    {
        if($fields[$i] =~ m/\d+/)
        {
            $level=$fields[$i]-$energy_1s;
            $OUTPUT[$i]=$OUTPUT[$i].sprintf("%.4f",$level)."\t";
#           if($Li_num && $i==($Li_num+8+1)){
 #          print "$level\n";
  #          }
        }
    }
    $OUTPUT[0]=$OUTPUT[0]."$_\t";
    reset $lines;
    #reset $Li_num;
}

open OUTFILE, ">", "Levels.dat";
foreach(@OUTPUT){print OUTFILE; print OUTFILE "\n";}

chomp($pwd=`pwd`);
$title= $pwd;
my $plot_filename=$title;
$plot_filename=~ s!/!-!g;
$plot_filename=$plot_filename."levels";
#print $plot_filename;

if(1) #easy suppression on gnuplot call during debugging
{
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
#    open my $PROGRAM, '|-', 'less';

    #say {$PROGRAM} "set title 'Energy Levels'";
    say {$PROGRAM} "set title '$title'";

if(1)  #if commandline arg -f then this will output to file; otherwise X11 output
{
    $ylshort =~ s/\s+//;
    say {$PROGRAM} 'set terminal postscript color solid';
    say {$PROGRAM} "set output '$plot_filename.ps'";
}

    $xmin=0;
    $xmax=100;
    $ymin=0;
    $ymax=1.4;
    say {$PROGRAM} "set xrange[$xmin:$xmax]";
    say {$PROGRAM} "set xtics 5";
    say {$PROGRAM} "set ytics 0.1";
    say {$PROGRAM} "set yrange[$ymin:$ymax]";

#Change labels for new variables
    my ($xlabel, $ylabel, $xlshort, $ylshort);

    #my @latticeInfo=`grep celldm *in`;
    #foreach(@latticeInfo) {~ s/^.*celldm//; ~ s/  \s+/  /; chomp}
    #$xlabel=join(' ', @latticeInfo);
    $xlabel='States';
    $ylabel='eV';
    
    say {$PROGRAM} "set grid";
    say {$PROGRAM} "set ylabel '$ylabel'";
    say {$PROGRAM} "set xlabel '$xlabel'";
    say {$PROGRAM} "set key autotitle columnhead";
    #say {$PROGRAM} "set terminal X11";
#    say {$PROGRAM} "set terminal postscript color";
 #   say {$PROGRAM} "set output 'Random.ps'";
    
    print {$PROGRAM} "plot";
    for (my $i=0; $i<@dirs; $i++)
    {
        print {$PROGRAM} " 'Levels.dat' u ".eval($i+1);
        if( $i<(@dirs-1)){print {$PROGRAM} ',' }
    }
#    print {$PROGRAM} "$plot";
    print $PROGRAM "\n\n";
    close $PROGRAM;
}



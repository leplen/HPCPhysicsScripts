#!/usr/bin/perl
#
#use warnings;
use 5.010; #provides the say command
use Getopt::Std;

my %args;
getopt('f', \%args);

$PSfile=0;
if(exists $args{f}) {$PSfile=1}


chomp($pwd=`pwd`);
$title= $pwd;
$title =~ s!.*MoreInterface/!!;
my $plot_filename=$title;
$plot_filename=~ s!/!-!g;
#@labels=('1+4','3+5','4','7+8+9');
@labels=('1+2+3','4+5','6+7','8+9','10','11','12');
#@labels=('1+11','2+10','3+9','4+5+6+7+8','12+13');

my @legend=('Messy-Li', 'Li3PS4-Li','Slab Li', 'Messy-P', 'Li3PS4-P', 'Messy-S', 'Li3PS4-S');
my @legend=@labels;

if(1) #easy suppression on gnuplot call during debugging
{
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
  #open my $PROGRAM, '|-', 'less'; #for viewing instructions to gnuplot

    say {$PROGRAM} "set title '$title'";

    $xmin=-12.5;
    $xmax=5;
    $ymin=0;
    $ymax=3;
    say {$PROGRAM} "set xrange[$xmin:$xmax]";
    say {$PROGRAM} "set yrange[$ymin:$ymax]";

#Change labels for new variables
    my ($xlabel, $ylabel, $xlshort, $ylshort);
    $xlabel='Energy (eV)';
    $ylabel='DOS';
    if($xlabel =~ /(^\w+)/) {$xlshort=$1}; 
    if($ylabel =~ /(^\w+\s*\w+)/) {$ylshort=$1}; 
    
    say {$PROGRAM} "set ylabel '$ylabel'";
    say {$PROGRAM} "set xlabel '$xlabel'";
if($PSfile)  #if commandline arg -f then this will output to file; otherwise X11 output
{
    $ylshort =~ s/\s+//;
    say {$PROGRAM} 'set terminal postscript color solid';
    say {$PROGRAM} "set output '$plot_filename.ps'";
}
    #say {$PROGRAM} "set style line 3 lw 2 lt 5 ";    
#    say {$PROGRAM} "set style line 3 lw 2 ";    
    my @entries;
    print {$PROGRAM} "plot";
    for (my $i=0; $i<@labels; $i++)
    {
        @entries=split(/\+/,$labels[$i]);
        print {$PROGRAM} " 'pDOSplot.dat' u 1:((";
        foreach(@entries) 
        {
            print {$PROGRAM} "\$".eval($_+1)."+";
        }
        print {$PROGRAM} "".eval($i*0.005).")/".eval(0+@entries).") w l lt 2 lc $i lw ".eval(1+(@labels-$i)*1/@labels).
        " title '$legend[$i]'";

        if( $i<(@labels-1)){print {$PROGRAM} ',' }else
        {print {$PROGRAM} ",'<echo ".eval(&FermiFix-45.4977)." $ymax' w impulse lc 'black' title 'Fermi En'\n"}
    }
#    print {$PROGRAM} "$plot";

    close $PROGRAM;
}

sub FermiFix #uses the Li 1s states to set the fermi level to that of bulkLi.
{
   $lines=`tac *.out|grep -A 100 "Fermi ener"|head -n 100|tac`; 
   # $lines=`grep -B 100 "Fermi ener" $tempdir*out`;
    $lines=~ s/^.*k(?!.*k)//s; #black lookahead magic http://www.perlmonks.org/?node_id=518444
    
    if($lines=~ m/ev.*?(-\d+\.\d+)/s)
    {
        $energy_1s=$1;
        $lines=~ m/Fermi energy is\s+(-?\d+\.\d+)/;
        $fermiLevel=$1;
        $energy=$fermiLevel-$energy_1s;
       # print "$tempdir:\t$energy\n";
    }
}



#It should in principle be possible to group things pretty easily, but I'm not 
#totally sure what the best way to specify which groups I want combined.
#plot u 1:($2+$4) is pretty straightforward, but the existing complexity is defeating me at the moment 

#!/usr/bin/perl
use strict; 
use 5.010; 

# Calculates the k-point density for each record
use constant PI    => 4 * atan2(1, 1);
my($kpointN, $cellVol, $kDen, $dir);

my $plot="";
open (FILE, "<", "$ARGV[0]") or die "Can't find $ARGV[0]!" ;
my $file=do {local $/; <FILE>};
my @records=split(/Directory:/, $file);
foreach(@records)
{
    if(/(\/wfurc4.*)/){$dir=$1}
    if(/k-points are (\d+)\s+(\d+)\s+(\d+)/){$kpointN=$1*$2*$3;}
    if(/new unit-cell volume\s+=.*\s(\d+\.\d+)\s+Ang/){$cellVol=$1}

    if($kpointN && $cellVol) {
        $kDen=(2*PI)**3/$cellVol/$kpointN;
        #print "$dir\n$kDen\t\t$kpointN\t$cellVol\n";
#        print "$kDen\t$dir\n";
        $plot="$plot"."$kDen\n";
    #    push(@Dens,$kden);
    }
}
$plot="$plot"."e\n";
#print $plot;
if(1) #easy suppression on gnuplot call during debugging
{
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
   # open my $PROGRAM, '|-', 'less' or die "Couldn't pipe to gnuplot: $!";
    say {$PROGRAM} "set xrange[0:0.07]";
#    say {$PROGRAM} "set yrange[0:15]";
    #say {$PROGRAM} "set key outside";
   # say {$PROGRAM} "set key left top";

    say {$PROGRAM} "set style histogram clustered gap 1";
#    say {$PROGRAM} "set style fill pattern";
 
    say {$PROGRAM} "binwidth=0.001";
    say {$PROGRAM} "bin(x,width)=width*floor(x/width) + binwidth/2.0";
    say {$PROGRAM} "set boxwidth binwidth";
#Change labels for new variables
    my ($xlabel, $ylabel, $xlshort, $ylshort);
    #$xlabel='P number/area';
#    $xlabel='Delta H (meV/sq. Bohr)';
    $xlabel='Delta H (meV/sq. bohr)';
    $ylabel='Counts';
    if($xlabel =~ /(^\w+)/) {$xlshort=$1}; 
    if($ylabel =~ /(^\w+\s*\w+)/) {$ylshort=$1}; 
    
    say {$PROGRAM} "set ylabel '$ylabel'";
    say {$PROGRAM} "set xlabel '$xlabel'";
if(0)  #1 for output to file; 0 for X11 output
{
    $ylshort =~ s/\s+//;
    say {$PROGRAM} 'set terminal postscript color solid';
    say {$PROGRAM} "set output '$xlshort-$ylshort.ps'";
}
    print {$PROGRAM} "plot";
    my %fillstyle;
#    $fillstyle{'Pmn21-Li3PO4'}="fs empty";
 #   $fillstyle{'pnma-Li3PO4'}="fs pattern 4";
  #  $fillstyle{'Pmn21-Li3PS4'}="fs empty";
   # $fillstyle{'pnma-Li3PS4'}="fs pattern 5";
   # for (my $i=0; $i<@materials; $i++)
    #{
        say {$PROGRAM} " '-' u (bin(\$1,binwidth)):(1.0) smooth freq with boxes";
    #}
    print {$PROGRAM} "$plot";

    close $PROGRAM;
}


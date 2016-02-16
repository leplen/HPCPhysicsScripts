#!/usr/bin/perl
use strict; 
use 5.010;


my $Ry2eV=13.60569193;

#open (FILE, "<", "$ARGV[0]") or die "Can't find $ARGV[0]!" ;
my $inputFile="./ComboFile";
open (FILE, "<", "$inputFile") or die "Can't find $inputFile" ;
my $file=do {local $/; <FILE>}; #read file into single scalar

my $plot; #what will get passed to gnuplot
my $xmin=10000; #sets the bounding box for gnuplot a little more intelligently
my $xmax=-10000;
my $ymin=10000;
my $ymax=-10000;


my @records=split(/Directory:/, $file);
shift(@records);
foreach(@records)
{
    reset;
    my ($dir, $ecut, $atomlist, $atom_num, $P_num, $Li_num, $CPUtime, $cycles, $calc, $inLat, $outLat, $area);
    my ($DEL_H, $form_diff, $Ui, $raw_en);
    if(/(\/wfurc4.*)/){$dir=$1}
    if(/Ecut is (\d+)/){$ecut=$1}
    if(/Calculation is (\w+-?\w*)/){$calc=$1}
    if(/There are (\d+) atoms/){$atom_num=$1; }
    if(/P:(\d+)/){$P_num=$1; }
    if(/Li:(\d+)/){$Li_num=$1; }
    if(/Input lattice:\s+(.*)/){$inLat=$1}

#    if($dir =~/x-interface/){
#        if(/Output lattice:\s*(.*)/){$outLat=$1; $area=&find_areaX($outLat)}
#        else{$area=&find_areaX($inLat)}
#    }
#    elsif($dir =~/y-interface/){
#        if(/Output lattice:\s*(.*)/){$outLat=$1; $area=&find_areaY($outLat)}
#        else{$area=&find_areaY($inLat)}
#    }
    if(/Output lattice:\s*(.*)/){$outLat=$1; $area=&find_areaY($outLat)}
    else{$area=&find_areaY($inLat)}


    if(/Ui is (-\d+\.\d+)/) {$Ui=$1;}
    if(/Formation diff.*, (-?\d+\.\d+)/) {$form_diff=$1;}
    if(/Delta H:\s+(-\d+\.\d+)/) {$DEL_H=$1}
    if(/\s+=\s+(-\d+\.\d+)/) {$raw_en=$1}

    my $diff=$form_diff-$DEL_H; 
    my $Li_num=$Li_num-3*$P_num;
#    if($atom_num == 80 && $calc eq 'vc-relax' && $Ui<0 )
    if($Li_num>0 and $P_num >0)
    {
       
################################
#   Change x and y values here
        my $x=$Li_num; #/$area; 
        my $y=$diff;
        print "$dir  $x  $y $P_num $area $outLat\n";
    #    print "$dir  $x  $y ######## $P_num $area\n";
        
        #if($y>100){print "$dir  $x  $y\n\n\n";}
################################
################################
        $plot=$plot."$x $y\n";
        if($x < $xmin) {$xmin=$x-.1*abs($x)}
        if($x > $xmax) {$xmax=$x+.1*abs($x)}
        if($y < $ymin) {$ymin=$y-.2*abs($y)}
        if($y > $ymax) {$ymax=$y+.2*abs($y)}
        #$ymin=0;
        #$ymax=10;
    }


} ###End Foreach
#print $plot;

if(1) #easy suppression on gnuplot call during debugging
{
    $plot=$plot."e\n";
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
    say {$PROGRAM} "set xrange[$xmin:$xmax]";
    say {$PROGRAM} "set yrange[$ymin:$ymax]";

#Change labels for new variables
    my ($xlabel, $ylabel, $xlshort, $ylshort);
    #$xlabel='P number/area';
    $xlabel='Li number';
    $ylabel='Formation energy(eV)';
    if($xlabel =~ /(^\w+)/) {$xlshort=$1}; 
    if($ylabel =~ /(^\w+\s*\w+)/) {$ylshort=$1}; 
    
    say {$PROGRAM} "set ylabel '$ylabel'";
    say {$PROGRAM} "set xlabel '$xlabel'";
if(0)  #1 for output to file; 0 for X11 output
{
    $ylshort =~ s/\s+//;
    say {$PROGRAM} 'set terminal postscript';
    say {$PROGRAM} "set output '$xlshort-$ylshort.ps'";
}
    say {$PROGRAM} "plot '-' using (\$1):(\$2) with points ps 3 title '$ylabel vs $xlabel'";
    print {$PROGRAM} "$plot";

    close $PROGRAM;
}



sub find_areaX #I'm not sure about this for non-Ortho stuff
{
    my ($cd1,$cd2,$cd3,$area);
    foreach(@_)
    {
        if(/celldm1:\s+(\d+\.\d+)/){$cd1=$1}
        if(/celldm2:\s+(\d+\.\d+)/){$cd2=$1}
        if(/celldm3:\s+(\d+\.\d+)/){$cd3=$1}
    }
$area=$cd1**2*$cd3*$cd2;
}
sub find_areaY #I'm not sure about this for non-Ortho stuff
{
    my ($cd1,$cd2,$cd3,$area);
    foreach(@_)
    {
        if(/celldm1:\s+(\d+\.\d+)/){$cd1=$1}
        if(/celldm2:\s+(\d+\.\d+)/){$cd2=$1}
        if(/celldm3:\s+(\d+\.\d+)/){$cd3=$1}
    }
$area=$cd1**2*$cd3;
}

#!/usr/bin/perl
use strict; 
open (FILE, "<", "$ARGV[0]") or die "Can't find $ARGV[0]!" ;
my $file=do {local $/; <FILE>};

my @records=split(/Directory:/, $file);
foreach(@records)
{
    my ($dir, $ecut, $atomlist, $atom_num, $CPUtime, $cycles, $calc, $inLat, $outLat);
    my ($Fin_en);
    if(/(\/wfurc4.*)/){$dir=$1}
    if(/Ecut is (\d+)/){$ecut=$1}
    if(/Calculation is (\w+-?\w*)/){$calc=$1}
    if(/There are (\d+) atoms/){$atom_num=$1; }
    if(/Input lattice:\s+(.*)/){$inLat=$1}
    if(/Output lattice:\s*(.*)/){$outLat=$1}
    if(/\nCPUtime:\s+(\d+):(\d+):(\d+)/) {$CPUtime=$1*60*60+$2*60+$3;}
    if(/Current en/) {print "$dir\n"}
    if(/=\s+(-\d+\.\d+)/) {$Fin_en=$1;}


    if($_ =~ /dofree is y/)
    #{print "$dir\t$atom_num\t$Fin_en\n" }
    {print }
}


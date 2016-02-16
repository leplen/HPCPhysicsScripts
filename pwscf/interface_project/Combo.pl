#!/usr/bin/perl
use strict; 


#my $material='pnma-Li3PS4';
my $material='Pmn21-Li3PO4';
#my $material='Li4P2S6';
print "Material for formation energy is $material";
if ($material) {unless (&Formation_energy("$material")) {warn "$material not found\n";} }

system('summary.pl>myTemporaryFile');
#open (UIFILE, "<", "UIfile") or die "Can't find UIfile" ;
#open (FEFILE, "<", "Form-En-file") or die "Can't find Form-En-file" ;
open (SUMFILE, "<", "myTemporaryFile") or die "Can't find sumFile" ;
#my $UIfile=do {local $/; <UIFILE>};
#my $Enfile=do {local $/; <ENFILE>};
my $sumfile=do {local $/; <SUMFILE>};
my @records=split(/Directory:/, $sumfile);
shift(@records);


open (COMBOFILE, ">", "ComboFile");
foreach(@records)
{
    my ($dir, $ecut, $atomlist, $atom_num, $P_num, $CPUtime, $cycles, $calc, $inLat, $outLat);
    my ($Ref_en, $Fin_en);
    if(/(\/wfurc4.*)/){$dir=$1}
    if(/Ecut is (\d+)/){$ecut=$1}
    if(/Calculation is (\w+-?\w*)/){$calc=$1}
    if(/There are (\d+) atoms/){$atom_num=$1; }
    if(/P:(\d+)/){$P_num=$1; }
    if(/Input lattice:\s+(.*)/){$inLat=$1}
    if(/Output lattice:\s*(.*)/){$outLat=$1}
    if(/\nCPUtime:\s+(\d+):(\d+):(\d+)/) {$CPUtime=$1*60*60+$2*60+$3;}
    #if(/Current en/) {print "$dir\n"}
    if(/Reference enthalpy: (-?\d+\.\d+)/){$Ref_en=$1; }
    if(/=\s+(-\d+\.\d+)/) {$Fin_en=$1;}

    chomp;
    print COMBOFILE 'Directory:';
    print COMBOFILE;
    print COMBOFILE "Formation diff(Ryd,eV): ",($Fin_en-$Ref_en), ", ", ($Fin_en-$Ref_en)*13.60569193, "\n";
#    if($P_num) {print "$P_num Formula Units elec. Delta H: ",$P_num*&Formation_energy('beta-Li3PO4'),"\n"}
    if($P_num) {print COMBOFILE "$P_num Formula Units elec. Delta H: ",$P_num*&Formation_energy("$material"),"\n"}
    print COMBOFILE "\n";
    reset;
}

system('rm -f myTemporaryFile');

sub Formation_energy#Takes a compound as an argument and returns its formation energy in eV/Formula Unit
{
my %Form_en;
$Form_en{ 'Li6P6O18' }=-76.333417758;
$Form_en{ 'Li2O' }=-6.101611374;
$Form_en{ 'Li2O2' }=-6.354939951;
$Form_en{ 'Li2S' }=-4.300254320;
$Form_en{ 'Li2S2' }=-4.089064874;
$Form_en{ 'alpha-Li3N' }=-1.596002944;
$Form_en{ 'Li3P' }=-3.470349917;
$Form_en{ 'LiPN2' }=-3.646348537;
$Form_en{ 'N2O5' }=-0.940974134;
$Form_en{ 'h-P2O5' }=-15.449129170;
$Form_en{ 'o-P2O5' }=-15.780369355;
$Form_en{ 'P3N5' }=-3.020944914;
$Form_en{ 'P2S5' }=-1.929090092;
$Form_en{ 'P4S3' }=-2.446556763;
$Form_en{ 'SO3' }=-4.835973521;
$Form_en{ 'LiNO3' }=-5.366796892;
$Form_en{ 'LiPO3' }=-12.745956511;
$Form_en{ 'gamma-Li3PO4' }=-21.196351728;
$Form_en{ 'pnma-Li3PO4' }=-21.196351728; #identical to gamma-Li3PO4
$Form_en{ 'beta-Li3PO4' }=-21.227471925;
$Form_en{ 'Pmn21-Li3PO4' }=-21.227471925; #identical to beta-Li3PO4
$Form_en{ 'Li4P2O6' }=-29.718594718;
$Form_en{ 'Li4P2O7' }=-33.967174049;
$Form_en{ 'Li5P2O6N' }=-33.178686846;
$Form_en{ 'gamma-Li3PS4' }=-8.370601535;
$Form_en{ 'Pmn21-Li3PS4' }=-8.370601535; #identical to gamma-Li3PS4
$Form_en{ 'beta-Li3PS4-pureb' }=-8.282832951; 
$Form_en{ 'pnma-Li3PS4' }=-8.282832951; #identical to beta-Li3PS4-pureb
$Form_en{ 'beta-Li3PS4-purec' }=-8.250715389;
$Form_en{ 'beta-Li3PS4-gammaLi3PO4structure' }=-8.175350570;
$Form_en{ 'Li4P2S6' }=-12.421166202;
$Form_en{ 'Li4P2S7' }=-11.586444289;
$Form_en{ 'Li2SO4' }=-14.633052560;
$Form_en{ 'SD-Li2PO2N' }=-12.474427450;
$Form_en{ 's1-Li2PO2N' }=-12.346652043;
$Form_en{ 's2-Li2PO2N' }=-12.376611233;
$Form_en{ 'SD-Li2PS2N' }=-5.801157047;
$Form_en{ 'Li2POSN-Conf1' }=-9.089841130;
$Form_en{ 'Li7P3S11' }=-20.014852940;
$Form_en{ 'Li7P3O11' }=-54.843713069;
$Form_en{$_[0]};
}


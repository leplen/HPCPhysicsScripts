#!/usr/bin/perl
#
#use warnings;
use POSIX; #provides floor command

open INPUT, "<", "next1.pbs";

$inputfile= do {local $/; <INPUT>};

unless($inputfile) {die "next1.pbs file not found\n"}

#print $inputfile;
#if($inputfile =~ /PBS -l mem=(.*)\n/){$mem=$1}
if($inputfile =~ /PBS -N\s+(.*)\n/){$label=$1}
if($inputfile =~ /(&SYSTEM.*&ELECTRONS)/s){$systemcard=$1}
if($inputfile =~ /(ATOMIC_SPECIES.*K_POINTS AUTOMATIC)/s){$atomcard=$1}


$elecLine=`grep -a "number of electrons" *out`;
if ($elecLine =~ /number of electrons\s+=\s+(\d+)/) {$electrons=$1}
else{warn "Electron number not found\n"; $electrons=160;}
$bands=floor($electrons*1.00);

$template=&template; #creates template string using sub-routine

$template =~ s/Li2O/$label/g;
$template =~ s/&SYSTEM.*&ELECTRONS/$systemcard/s;
$template =~ s/ATOMIC_SPECIES.*K_POINTS AUTOMATIC/$atomcard/s;
$template =~ s/&SYSTEM/&SYSTEM\n  nbnd = $bands,/;
$template =~ s/ATOMIC_SPECIES.*K_POINTS AUTOMATIC/$atomcard/s;

#print $template;
system('mkdir DOS');
open DOS, ">", "DOS/DOScalc.pbs";
print DOS $template;


sub pretty_pos
{
    foreach (@_)
    {
    ~ s/\s.*e-.*\s/ 0 /;
    ~ s/\s0\s/ 0.00 /;
    if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}
    if (/\s1\./) {~ s/(\s1\.)/\t0./g}

    if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
    {$_=sprintf( "%s\t%.8f %.8f %.8f\n" , $1, $2, $3, $4 )}
    }
    return @_;
}








#PBS -W x=\"NODESET=ONEOF:FEATURE:ethernet:tengig\"
sub template {
q(#!/bin/tcsh
#
#PBS -l nodes=1:ppn=16:ethernet
#PBS -W group_list=natalieGrp
#PBS -j oe
#PBS -m a
#PBS -N Li2O
#PBS -l walltime=80:00:00
#PBS -l cput=2800:00:00
#PBS -l mem=95gb
#PBS -q rhel6
#
echo 'hostname' `/bin/hostname`
echo 'job directory' `pwd`
#
setenv TMPDIR /scratch/$PBS_JOBID
echo 'Reset TMPDIR for this job to ' $TMPDIR

source /etc/profile.d/modules.csh
module load openmpi/1.6-intel

set PW=/home/natalie/EL6/developcode/PWscf/mod5.1/espresso-5.1/bin/pw.x
set DOS=/home/natalie/EL6/developcode/PWscf/mod5.1/espresso-5.1/bin/dos.x
set PDOS=/home/natalie/EL6/developcode/PWscf/mod5.1/espresso-5.1/bin/projwfc_paw.x


cd ${PBS_O_WORKDIR}

set TMP_DIR='./'
set outd='./'
set label='Li2O'

cat > Li2O.in << EOF
&CONTROL
  calculation = "scf",
  pseudo_dir  = '/wfurc4/natalieGrp/leplnd6/paw/WebProject/',
  verbosity   = "high",
  outdir      = "$outd",
  restart_mode = 'from_scratch',
  prefix       ='$label',
  nstep = 300,
  dt = 20,
  forc_conv_thr = 1.0D-5,
  etot_conv_thr = 1.0D-6,
  tstress = .true.,
  tprnfor = .true.,
/
&SYSTEM
  ibrav       = 2,
  celldm(1)   =   8.50117355077963,
  nat         = 3,
  ntyp        = 2,
  nosym       =.FALSE.,
  ecutwfc     = 64.D0,
  occupations = "smearing",
  smearing    = "gaussian",
  degauss     = 0.001D0,
  nbnd = 80,
/
&ELECTRONS
  conv_thr    = 1.D-8,
  electron_maxstep = 200,
/
&IONS
/
&CELL
/
ATOMIC_SPECIES
Li  6.914    Li.LDA-PW-paw.UPF
O   15.9994  O.LDA-PW-paw.UPF
ATOMIC_POSITIONS {crystal}
Li      0.25   0.25    0.25
Li     -0.25  -0.25   -0.25
O       0.00   0.00    0.00
K_POINTS AUTOMATIC
8 8 8 1 1 1
EOF

mpirun $PW  -in  Li2O.in  >  Li2O.out

cat > Li2O.dos.in << EOF
   &dos
     outdir='$outd/',
     prefix='$label',
     fildos='dos',
     Emin=-20.0, Emax=12.0, DeltaE=0.01,
     ngauss=0,  degauss=0.01
/
EOF

mpirun $DOS -in  Li2O.dos.in >  Li2O.dos.out

cat > Li2O.pdos.in << EOF
   &projwfc
     outdir='$outd/',
     prefix='$label',
     filpdos='pdos',
     Emin=-20.0, Emax=12.0, DeltaE=0.01,
     ngauss=0, degauss=0.01,
/
EOF

mpirun $PDOS -in  Li2O.pdos.in >  Li2O.pdos.out
);
}


=head

Deprecated feature made obsolete by better plotting program.
my ($xmin, $xmax, $ymin, $ymax, $zmin, $zmax);
$xmin=$ARGV[0];
$xmax=$ARGV[1];
$ymin=$ARGV[2];
$ymax=$ARGV[3];
$zmin=$ARGV[4];
$zmax=$ARGV[5];


#This block goes through the atomic positions and replaces all Li atoms in box given 
#as a commandline argument with Lm atoms. This makes it easy to distinguish between
#electrolyte Li and metallic Li
if($ARGV[4])  #only run if the commandline arguments defining the bounding box are present
{
    $atomcard =~ s/ATOMIC_SPECIES/ATOMIC_SPECIES\nLm  6.914    Lm.LDA-PW-paw.UPF/;
    @pos_raw=split("\n",$atomcard);
    @pos=&pretty_pos(@pos_raw);
    foreach $line (@pos)
    {
        if($line =~ m/\s*\w+\s+(\d\.\d+)\s+(\d\.\d+)\s(\d\.\d+)/)
        {
            $x=$1; $y=$2; $z=$3;
            if( $xmin < $x && $x< $xmax && $ymin < $y && $y < $ymax && $zmin < $z && $z < $zmax )
            {
                $line =~ s/Li/Lm/;
                #print "$line\n";
            }
        }

    }
    $atomcard=join("\n",@pos); 

    $systemcard =~ s/(ntyp\s+=\s*)(\d+)/$1.($2+1)/e
}

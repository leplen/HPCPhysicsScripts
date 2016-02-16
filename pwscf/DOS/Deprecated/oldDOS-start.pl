#!/usr/bin/perl
#
use warnings;
use POSIX; #provides floor command

open INPUT, "<", "next1.pbs";

$inputfile= do {local $/; <INPUT>};


#print $inputfile;
#if($inputfile =~ /PBS -l mem=(.*)\n/){$mem=$1}
if($inputfile =~ /PBS -N\s+(.*)\n/){$label=$1}
if($inputfile =~ /(&SYSTEM.*&ELECTRONS)/s){$systemcard=$1}
if($inputfile =~ /(ATOMIC_SPECIES.*K_POINTS AUTOMATIC)/s){$atomcard=$1}


$elecLine=`grep -a "number of electrons" *out`;
if ($elecLine =~ /number of electrons\s+=\s+(\d+)/) {$electrons=$1}
else{warn "Electron number not found\n"; $electrons=160;}
$bands=floor($electrons*0.75);

$template=&template; #creates template string using sub-routine

$template =~ s/Li2O/$label/g;
$template =~ s/&SYSTEM.*&ELECTRONS/$systemcard/s;
$template =~ s/ATOMIC_SPECIES.*K_POINTS AUTOMATIC/$atomcard/s;
$template =~ s/&SYSTEM/&SYSTEM\n  nbnd = $bands,/;

#print $template;
system('mkdir DOS');
open DOS, ">", "DOS/DOScalc.pbs";
print DOS $template;









#PBS -W x=\"NODESET=ONEOF:FEATURE:ethernet:tengig\"
sub template {
q(#!/bin/tcsh
#
#PBS -l nodes=1:ppn=16:tengig
#PBS -W group_list=natalieGrp
#PBS -j oe
#PBS -m a
#PBS -N Li2O
#PBS -l walltime=150:00:00
#PBS -l cput=2400:00:00
#PBS -l mem=45gb
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
  pseudo_dir  = '/wfurc4/natalieGrp/natalie/EL6/PAWatoms/WebProject/',
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
  cell_dynamics='bfgs',
  wmass = 1.0,
  press = 0.0,
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
     Emin=-16.0, Emax=16.0, DeltaE=0.01,
     ngauss=0,  degauss=0.01
/
EOF

mpirun $DOS -in  Li2O.dos.in >  Li2O.dos.out

cat > Li2O.pdos.in << EOF
   &projwfc
     outdir='$outd/',
     prefix='$label',
     filpdos='pdos',
     Emin=-16.0, Emax=16.0, DeltaE=0.01,
     ngauss=0, degauss=0.01,
/
EOF

mpirun $PDOS -in  Li2O.pdos.in >  Li2O.pdos.out
);
}

#!/usr/bin/perl
#use warnings;




my $pbsfile;
###########################
{ #Start read operation
my @pbsfiles;my $input_file;
opendir(DIR,".") or die "opening directory failed:$!";  
my @files=readdir(DIR);
foreach(@files)
{
    if (@ARGV<1) { if($_=~/pbs$/) {push @pbs, $_;} }
    else {$pbs[0]=$ARGV[0];}
    if($_=~/.out$/) {$output_file=$_;}
}
closedir(DIR);
if(@pbs==1){$input_file=$pbs[0];}
else{die "Too many pbs files found.\n Give the one you want as a commandline argument."; }
#I could do something really clever with a diff on the .in file for multiple pbs files.

open (PBSFILE, "<", "$input_file") or die "Can't find $input_file!" ;
$pbsfile = do { local $/; <PBSFILE> };

#print "Input is $input_file\n";
if($input_file =~ /next1\.pbs/){die "next1.pbs file already exists\n";}
} #End file read operation
###########################

if ($pbsfile =~ /\s+nat\s*=\s*(\d+)\s*,/) {$atom_number=$1}
else {die "Couldn't determine # of atoms\n";}

#Finding the last instance of the positions in our file:
@lines=`grep -a ATOMIC_ -A $atom_number $output_file|tail -n $atom_number`;
@lines=&pretty_pos(@lines);
$pbsfile=~ s/ATOMIC_POSITIONS\s*{crystal}.*K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n @lines\n K_POINTS AUTOMATIC/s;

if($pbsfile =~ /vc-relax/)
{
    $alat=`grep -am 1 alat $output_file`;
    $alat =~ m/(\d+\.\d+)/; $alat=$1;
    $cell=`PWscf_triclinic $output_file $alat|grep celldm`;
    $cell =~ s/^\s+//;
    $cell =~ s/\n\s+/\n  /g;

#depending on ibrav you might have to fuss with this a bit, set up for orthorhomb & triclinic currently
    unless($cell =~ /celldm\(4\) =\s+0\.000/ 
       and $cell =~ /celldm\(5\) =\s+0\.000/
       and $cell =~ /celldm\(6\) =\s+0\.000/ )
    {
        $pbsfile =~ s/ibrav\s*=\s*\d+/ibrav       = 14/;
        $pbsfile =~ s/celldm\(1.*celldm\(\d\)\s*=\s*\d+\.\d+\s*,/$cell/s;
    }else
    {
        $cell =~ s/\s+celldm\(4.*//s;
        $pbsfile =~ s/celldm\(1.*celldm\(\d\)\s*=\s*\d+\.\d+\s*,/$cell/s;
    }
}
#system ("mkdir bfgs_old; find . -maxdepth 1 -type f -exec mv {} ./dir \;;");
open OUTPUT, ">", "next1.pbs" or die "Can't create Output\n";
print OUTPUT $pbsfile;
close OUTPUT;

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
#if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
#{printf( "%s\t(%.3f, %.3f, %.3f)\n" , $1, $2, $3, $4 )}

#This used to iterate over a lot of diectories, I'm 
#Not really as interested in having it do that anymore, but I 
#Might change my mind in the future, so here are all the old pieces
#foreach(@dirs)
#{
#
#grep "Final en" */*out -L|sed 's:/.*::'>crash_dirs
#open DIRS, "<", "crash_dirs" or die "Couldn't open $!";
#@dirs=<DIRS>;
#close DIRS;
#chomp(@dirs);
#system ("cd $_; mkdir bfgs_old; mv Li* bfgs_old; qsub bfgs_crash.pbs");
#$pbsfile=~ s/ATOMIC_POSITIONS\s*{crystal} ... K_POINTS AUTOMATIC/ATOMIC_POSITIONS {crystal}\n @lines\n K_POINTS AUTOMATIC/sg;

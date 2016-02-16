#!/usr/bin/perl
#
use warnings;
use Cwd;
#
#
my @dirs;
if($ARGV[0] && $ARGV[0] =~ /run/){@dirs=`find . -regex ".*\.o[0-9]+"`;} #can specify if "first_run dirs included"
else{@dirs=`find . -regex ".*\.o[0-9]+"|grep -v run|grep -v NEB`;}
my $cwd=getcwd;

foreach(@dirs)
{
    reset;
    s![^/]*$!!; #gets directory name from full torque output filename (i.e. mydir/Li3P.o123->mydir)#!
    s/\.//;
    my $tempdir=$cwd.$_;
   $lines=`tac $tempdir*.out|grep -A 200 "Fermi ener"|head -n 200|tac`; 
   # $lines=`grep -B 100 "Fermi ener" $tempdir*out`;
    $lines=~ s/^.*k(?!.*k)//s; #black lookahead magic http://www.perlmonks.org/?node_id=518444
    
    if($lines=~ m/ev.*?(-\d+\.\d+)/s)
    {
        $energy_1s=$1;
        $lines=~ m/Fermi energy is\s+(-?\d+\.\d+)/;
        $fermiLevel=$1;
        $energy=$fermiLevel-$energy_1s;
        print "$tempdir:\t$energy\n";
    }
#    print $lines;
}






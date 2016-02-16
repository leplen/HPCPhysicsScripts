#!/usr/bin/perl
#
#use warnings;
use 5.010;
use Getopt::Std;

my %args;
getopt('f', \%args);

$PSfile=0;
if(exists $args{f}) {$PSfile=1}

my @atoms;
{ #This section just saves the atomic symbols of the atoms from the input file into @atoms.
    my $atomlist; my @pbsfileNames; my $pbsfile;
    @pbsfileNames=<*pbs>; #matches pbs files in cwd;
    if(@pbsfileNames != 1) {warn "Multiple pbs files found\n"}
    print "Input is $pbsfileNames[0]\n";

    open PBSFILE, "<", $pbsfileNames[0]; #reads pbs file as single string into $pbsfile
    $pbsfile = do { local $/; <PBSFILE> };
    if($pbsfile =~ m/ATOMIC_SPECIES(.*)ATOMIC_POSITIONS/s){$atomlist=$1}else{die "Atom list not found\n"} #gets atomic species

    my @atomlines=split("\n", $atomlist);
    foreach(@atomlines) {if (/(Li|P|O|S|N|Lm)/) {push(@atoms, $1)} } #only atomic species saved to @atoms
}

#this adjusts the fermi level
chomp($fermi=`grep "Fermi energy is" *out`);
$fermi =~ s/.*is\s+(-?\d+\.\d+).*/$1/;
print "Fermi level is $fermi\n";

opendir(DIR, '.') or die "Opening directory failed:$!\n";
my @fileList=readdir(DIR);
foreach(@fileList)
{
    if(/pdos_atm/){push @DOS_files, $_}
}
closedir(DIR);
unless(@DOS_files) {die "DOS files not found\n"}


my (%fullhash, %atomhash); #,$n, $plot);

foreach $atom (@atoms) #array has 2-5 members
{
    foreach $file (@DOS_files)
    { 
        if ($file =~ /$atom/)
        {
            open DOSFILE, "<", "$file";
            while(<DOSFILE>)
            {
                if(/^\s*(-?\d+\.\d+)\s+(\d+\.\d+)E([+-]\d+)\s+(\d+\.\d+)/) 
                { 
                    $energy=$1; $density=$2*10**$3;
                    $energy=$energy-$fermi;
#                    print "$file, $energy, $density\n";
                    if($atomhash{$energy} ) {  $atomhash{$energy} = $atomhash{$energy} +$density; } 
                    else{  $atomhash{$energy} =$density; } #if undefined, define it
                }
            }
            close DOSFILE;
        }
    }
    
    #foreach $key (sort{$a<=>$b} keys %atomhash){ $plot=$plot.$key."\t".$atomhash{$key}."\n" } #energies are keys, densities are values this iterates through all energies 
    #$plot=$plot."e\n";
    
    if(%fullhash){ foreach $key(keys %atomhash){$fullhash{$key}="$fullhash{$key}\t".sprintf("%.4f",$atomhash{$key})}  }
    else{ foreach $key (keys %atomhash) {$fullhash{$key}=sprintf("%.4f",$atomhash{$key})}  }
    %atomhash=(); #reset atomhash b/c new group
}

open OUTPUT, ">", "pDOSplot.dat";
print OUTPUT "\#EN\t@atoms\n";
foreach $key (sort { $a <=> $b} keys %fullhash) {print OUTPUT sprintf("%.3f",$key);print OUTPUT "\t$fullhash{$key}\n"; } 


@group=@atoms; #default grouping is just broken down by atomic type
chomp($pwd=`pwd`);
$title= $pwd;
$title =~ s!/!-!g;
$title =~ s!.*MoreInterface-!!;
#print $title;

if(1) #easy suppression on gnuplot call during debugging
{
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
  #open my $PROGRAM, '|-', 'less'; #for viewing instructions to gnuplot

    say {$PROGRAM} "set title '$pwd'";

    $xmin=-25;
    $xmax=10;
    $ymin=0;
    $ymax=30;
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
    say {$PROGRAM} 'set terminal postscript color';
    say {$PROGRAM} "set output '$title.ps'";
}
    say {$PROGRAM} "set style line 3 linecolor rgb 'goldenrod' ";    
    print {$PROGRAM} "plot";
    for (my $i=0; $i<@group; $i++)
    {
        print {$PROGRAM} " 'pDOSplot.dat' u 1:".eval($i+2)." w l title '$group[$i]'";
        if( $i<(@group-1)){print {$PROGRAM} ',' }else{print {$PROGRAM} "\n"}
    }
#    print {$PROGRAM} "$plot";

    close $PROGRAM;
}

if(0)
{#
    chomp($nelec=`grep "number of electrons" *out`);
    $nelec =~ s/.*=\s+(\d+)\..*/$1/;
    #print "There are $nelec electrons\n";

    open DOS, "<", 'dos'; #reads pbs file as single string into $pbsfile

    $dummy=<DOS>; #makes while loop skip first line
    while(<DOS>) 
    {
        @fields=split;
        if($fields[-1]>$nelec/2)
        {
            $fermi=$fields[0];
            last;
        }
    }
}

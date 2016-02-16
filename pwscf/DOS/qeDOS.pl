#!/usr/bin/perl
#
#use warnings;
# 
# This used to try and do some really clever fixing of the fermi levels based off of the 1s levels of Li.
# Apparently that was a bad idea because those levels weren't that stable. Most of the fermi stuff has been
# commented out, but I haven't checked it super carefully.
#
use 5.010; #provides the say command
use Getopt::Std;

my %args;
getopt('f', \%args);

$PSfile=0;
$slices=1;
if(exists $args{f}) {$PSfile=1} #if receive f commandline argument, write output to file.
if(exists $args{r}) {$slices=0} #if receive r commandline argument, ignore regions

#This defines regions in case you want to split the DOS by location in system
my $dim=2; #1 for x, 2 for y, 3 for z
my $dimName; 
if($dim==1){$dimName='x'} elsif ($dim==2){$dimName='y'}elsif($dim==3){$dimName='z'}

my @regions;
unless($slices) {@regions=(0,1)}
else {
  #  @regions=(0,20,40,60, 100); 
    @regions=(0,30,35,100);
    #@regions=(0 .. 100); # ".." operator creates integer list 0..3 =0,1,2,3
    foreach(@regions) {$_ *= 0.01}
  #  foreach(@regions) {$_ += 0.02}
}
#This section just saves the atomic symbols of the atoms from the input file into @elementSyms
#And the coordinates into @atomicCoords.
my @atomicCoords;@elementSyms;
{
    my $atomlist; my $atomSyms; my @pbsfileNames; my $pbsfile;
    @pbsfileNames=<*pbs>; #matches pbs files in cwd;
    if(@pbsfileNames != 1) {warn "Multiple pbs files found\n"}
    print "Input is $pbsfileNames[0]. Interface normal dimension is $dimName\n";

    open PBSFILE, "<", $pbsfileNames[0]; #reads pbs file as single string into $pbsfile
    $pbsfile = do { local $/; <PBSFILE> };
    if($pbsfile =~ m/ATOMIC_POSITIONS(.*)K_POINTS/s){$atomlist=$1}else{die "Atom list not found\n"} #gets atomic species
    if($pbsfile =~ m/ATOMIC_SPECIES(.*)ATOMIC_POSITIONS/s){$atomSyms=$1}else{die "Atom list not found\n"} #gets atomic species

    my @atomicCoordTemps=split("\n", $atomlist);
    my @atomicSymbols=split("\n", $atomSyms);
    #print @atomicSymbols;
    foreach(@atomicSymbols) {if (/^\s*(Li|P|O|S|N|Sn)/) {push(@elementSyms, $1)} } #only atomic species saved to @atoms
#    foreach(@atomicSymbols) {if (/^\s*(P)/) {push(@elementSyms, $1)} } #only atomic species saved to @atoms
    my $i=0;
    foreach(@atomicCoordTemps) {if (/(Li|P|O|S|N|Sn)/) {$i++; push(@atomicCoords, "$i $_\n")} } #only selected atomic species get saved to coordinates
#    unless($i==$nat){die "Wrong number of atoms found\n"}
#print @atomicCoords;print @elementSyms;
}
#Define groups, and assigns atoms to them
#Groups are in element+region order (Li-R1,Li-R2...P-R1.,.S-R4)
my $group=0;my @grouplist;my @labels;my @groupnum;
foreach $Sym (@elementSyms) #iterate over atomic label
{
    for(my $k=1;$k<(@regions);$k++) #iterate over regions
    {
        foreach $atom (@atomicCoords) 
        {
            @fields=split(/\s+/,$atom);
            unless(@fields==2){ #checks if atom already assigned a group
                if( ($regions[$k-1]<=$fields[$dim+1]) && ($fields[$dim+1]<$regions[$k]) && $Sym eq $fields[1]) 
                {
        #            print $atom;
                    $grouplist[$group]="$grouplist[$group]"." $fields[0] ";
                    $groupnum[$group]++;
                }
            }
        }
        if($grouplist[$group]){push @labels, "$Sym($dimName<$regions[$k])"; } #if group contains members, save label
        $group++;
    }
}
#print @atomicCoords;
#
#At some point I may try to impement grouping
#my @entries;
#foreach(@comboList)
#{
#    @entries=split(/\+/);
#    print "Entries are @entries\n";
#}
#my $it=0;
#foreach(@grouplist) {print "$it $_\n"; $it++}
#print "AAAAAAAAAAAAAAAA\n";
#foreach(@groupnum) {print "$_\n"}
#
#
################################
#this sets the 0 of energy to the fermi level of bulk Li
chomp($fermiTemp=`grep "Fermi energy is" *out`);
$fermiTemp =~ s/.*is\s+(-?\d+\.\d+).*/$1/;
#print "System fermi level is $fermiTemp\nFermiFix gives ".&FermiFix."\n";
#$fermi=$fermiTemp-(&FermiFix-45.4977)-$originshift; #45.4977 is the bulk Li 1s-fermi level difference from /wfurc4/natalieGrp/leplnd6/pwscf/MoreInterface/Li2O/interface/110/small_cell/64k
#print "Bulk Li fermi level is $fermi\n";

################################################################
#Opening the DOS files and adding stuff together 
################################################################
opendir(DIR, '.') or die "Opening directory failed:$!\n";
my @fileList=readdir(DIR);
foreach(@fileList)
{
    if(/pdos_atm/){push @DOS_files, $_}
}
closedir(DIR);
unless(@DOS_files) {die "DOS files not found\n"}

$count=0; 
my (%fullhash, %atomhash); #,$n, $plot);
foreach $groupl (@grouplist) #$groupl is a string of  
{ $count++; if($groupl) 
{
    foreach $file (@DOS_files)
    { 
        ($file =~ /.*pdos_atm\#(\d+)\(.*/);
        my $atm_number=" $1 ";    
        if ($file =~ /.*Li.*/) {$Liweight=10}else{$Liweight=1}
#        print "Number is $atm_number for $file\n";
        if ($groupl =~ /$atm_number/)
            {# print "$count $file\n"
                open DOSFILE, "<", "$file";
                while(<DOSFILE>)
                {
                    if(/^\s*(-?\d+\.\d+)\s+(\d+\.\d+)E([+-]\d+)\s+(\d+\.\d+)/) 
                    { 
                        $energy=$1; $density=$Liweight*$2*10**$3/$groupnum[$count-1];
#                        $energy=$energy-$fermi;
    #                    print "$file, $energy, $density\n";
                        if($atomhash{$energy} ) {  $atomhash{$energy} = $atomhash{$energy} +$density; } 
                        else{  $atomhash{$energy} =$density; } #if undefined, define it
                    }
                }
                close DOSFILE;
            }
    }
    #foreach $key (sort{$a<=>$b} keys %atomhash){ $plot=$plot.$key."\t".$atomhash{$key}."\n" } 
    #$plot=$plot."e\n";
    #
    #This subtracts the Li metal density from the metallic Li group $Ligroup=3;
#    if($groupcount==$Ligroup){print $groupl;
 #   foreach $key(keys %atomhash){if(&LiEn($key))
  #  {print "$key $atomhash{$key}\t"; $atomhash{$key}=$atomhash{$key}-&LiEn($key); print "$atomhash{key}\n"; }}}
    #energies are keys, densities are values this iterates through all energies 
    if(%fullhash){ foreach $key(keys %atomhash){$fullhash{$key}="$fullhash{$key}\t".sprintf("%.6f",$atomhash{$key})}  }
    else{ foreach $key (keys %atomhash) {$fullhash{$key}=sprintf("%.6f",$atomhash{$key})}  }
    %atomhash=(); #reset atomhash b/c new group

}}    
open OUTPUT, ">", "pDOSplot.dat";
print OUTPUT "\#EN\t\t";
foreach (@labels){print OUTPUT "$_\t"}
#foreach $Sym (@elementSyms)
#{ for(my $k=1;$k<(@regions);$k++) {
#    print OUTPUT "$Sym"."_R$k\t"
#} }
print OUTPUT "\n";
foreach $key (sort { $a <=> $b} keys %fullhash) {print OUTPUT sprintf("%.3f",$key);print OUTPUT "\t\t$fullhash{$key}\n"; } 

chomp($pwd=`pwd`);
$title= $pwd;
$title =~ s!.*leplnd6/!!;
$title =~ s!.*MoreInterface/!!;
my $plot_filename=$title;
$plot_filename=~ s!/!-!g;
#print $title;

if(1) #easy suppression on gnuplot call during debugging
{
    open my $PROGRAM, '|-', 'gnuplot -persist' or die "Couldn't pipe to gnuplot: $!";
  #open my $PROGRAM, '|-', 'less'; #for viewing instructions to gnuplot

    say {$PROGRAM} "set title '$title'";

    $xmin=-21;
    $xmax=5.5;
    $ymin=0;
    $ymax=2.8;
    say {$PROGRAM} "set xrange[$xmin:$xmax]";
    say {$PROGRAM} "set yrange[$ymin:$ymax]";

#Change labels for new variables
    my ($xlabel, $ylabel, $xlshort, $ylshort);

    #my @latticeInfo=`grep celldm *in`;
    #foreach(@latticeInfo) {~ s/^.*celldm//; ~ s/  \s+/  /; chomp}
    #$xlabel=join(' ', @latticeInfo);
    $xlabel='eV';
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
    print {$PROGRAM} "plot";
    for (my $i=0; $i<@labels; $i++)
    {
        print {$PROGRAM} " 'pDOSplot.dat' u 1:(\$".eval($i+2)."+".eval($i*0.009).") ".
        "w l lt 2 lc $i lw ".eval(1+(@labels-$i)*1/@labels)." title '$labels[$i]'";
        if( $i<(@labels-1)){print {$PROGRAM} ',' }else
        {print {$PROGRAM} ",'<echo $fermiTemp $ymax' w impulse lc 'black' title 'Fermi En'\n"}
        #{print {$PROGRAM} ",'<echo ".eval(&FermiFix-45.496)." $ymax' w impulse lc 'black' title 'Fermi En'\n"}
        #{print {$PROGRAM} ",'<echo ".eval(&FermiFix-45.496)." 0' w impulse lc 'black' title 'Fermi En'\n"}
    }
#    print {$PROGRAM} "$plot";

    close $PROGRAM;
}

sub FermiFix #uses the Li 1s states to set the fermi level to that of bulkLi.
{
   $lines=`tac *.out|grep -A 200 "Fermi ener"|head -n 200|tac`; 
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
#EN		Li (z<0.2)	
sub LiEn
{
    my %LiHash;
    open LiDOS, "<", '/wfurc4/natalieGrp/leplnd6/pwscf/ECstability/Li/bccLi/single_cell/64k/DOS/pDOSplot.dat';
    while(<LiDOS>)
    {
        if(/^\s*(-?\d+\.\d+)\s+(\d+\.\d+)/) 
        { 
            $energy=$1; $density=$2;
            $LiHash{$energy} =$density; } #if undefined, define it
    }
    close DOSFILE;
    $LiHash{$_[0]};
}

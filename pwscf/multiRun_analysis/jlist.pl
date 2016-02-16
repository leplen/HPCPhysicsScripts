#!/usr/bin/perl
#
chomp($username=`whoami`);


chomp(@jobID=`qstat|grep $username`);
foreach(@jobID)
{
    if(/$username\s+(\d+.*)\s+R/){$Rtime=$1} #check if job is running
    else{$Rtime=0}
    ~s/\.r.*//;

    chomp($dir=`whatdir $_`);
    if($Rtime) #if running find pwscf convergence level
    {
        chomp($en=`energy_search.pl $dir*out`);
        $en =~ s/.*Conv:/Conv:/;
        unless($en =~ /Conv: -/) {$en =~ s/Conv:/Conv: /}
        #printf("'%6s': '%8s' R: '%50s',    $_: $Rtime R: $dir $en\n";
        printf("%6s: %8s R: %-120s %-10s\n",$_,$Rtime,$dir,$en);
    }
    else{printf("%6s: %8s Q: %-120s %-8s\n",$_,'00:00',$dir,'Conv:  0.00')}
}

=head 

This code calls a couple other scripts I wrote.
I've included the text of these scripts to make this more transparent/portable


whatdir: #returns directory name given pbs job id
DIR=`qstat -f $*|grep "Output" -A 2`;
DIR=`echo $DIR|sed -e s/^.*://`;
DIR=`echo $DIR|sed -e s/Priority.*$//`;
DIR=`echo $DIR|sed -e 's/ //g'`;
DIR=`echo $DIR|sed -e 's/=//g'`;
DIR=`echo $DIR|sed -e 's/[^/]*\.o[0-9]\+//'`;
echo "$DIR"



energy_search.pl: Returns level of convergence for pwscf relax/vc-relax calculation
unless(@ARGV) {
	$name=`find . -maxdepth 1 -type f -name '*out'`;
    chomp($name);
    push(@files,$name) ;
} else {
    @files=@ARGV;
}
foreach $file (@files) {
chomp(@lines=`fgrep -a "!   " "$file" |tail`);
unless(@lines) {next};
$lines[-1] =~m/(-\d+\.\d+)/;
$enlast=$1;
$lines[-2] =~m/(-\d+\.\d+)/;
$ennotlast=$1;
$diff=$enlast-$ennotlast;
print "$file EN: $enlast  Conv: $diff\n"; }


#!/usr/bin/perl
#
use List::Util qw(sum);


$latticeVec=1;



chomp(@lines=<STDIN>);

$distance=0;
foreach(@lines)
{
    @fields=split;
    if(@PreFields)
    {
        $distance=($fields[3]*3);
        $distance =~s/\d+(\.\d+)/0$1/;
        #$distance=($fields[3]-$PreFields[3])*$latticeVec;
        #if($distance>0.5 && $fields[2] <0.9 && $fields[2]>0.45){ push @AllDist, $distance}
    }
print;
print "\t$distance\n";
@PreFields=@fields;
}

#$AVG=sum(@AllDist)/@AllDist;
#print "Avg. is $AVG\n";

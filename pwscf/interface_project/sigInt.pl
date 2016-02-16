#!/usr/bin/perl
#
@lines=`grep celldm */*in`;

foreach(@lines) 
{
    if(/dm\(1\).*(\d+\.\d+)/)
    {
        if($cd1==$1 || $cd1==0){$cd1=$1;}else{$norm='x';print "Surface direction is x";}
    }
    if(/dm\(2\).*(\d+\.\d+)/)
    {
        if($cd2==$1 || $cd2==0){$cd2=$1;}else{$norm='y';print "Surface direction is y";}
    }
    if(/dm\(3\).*(\d+\.\d+)/)
    {
        if($cd3==$1 || $cd3==0){$cd3=$1;}else{$norm='z';print "Surface direction is z";}
    }
}

$Ang=0.52917721;
$cd1=$cd1*$Ang; #convert to angstroms
$cd2=$cd2*$cd1;
$cd3=$cd3*$cd1;

#if(

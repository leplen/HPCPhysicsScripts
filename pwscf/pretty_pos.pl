#!/usr/bin/perl
#
@lines=<STDIN>;
foreach (@lines) {
~ s/\S*e-\S*/ 0 /; #replace any space delimited field with e- notation with 0.
~ s/\s0\s/ 0.00 /g;
if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/eg}
if (/\s1\./) {~ s/(\s1\.)/\t0./g}

if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
{printf( "%s\t%.8f %.8f %.8f\n" , $1, $2, $3, $4 )}
}
#if (/(\w+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+(-?\d.\d+)\s+/) 
#{printf( "%s\t(%.3f, %.3f, %.3f)\n" , $1, $2, $3, $4 )}
#}

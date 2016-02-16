#!/usr/bin/perl
use warnings;
#This will go through a pwscf input file and generate a vacancy calculation for 
#each Li position.

my @dir;
$Li_num=$ARGV[0]; #This should change with the # of sites you're investigating
print "Proper syntax is:\n make_vac.pl 12 if 12 Li\n";

my $inputfile_name;  #if multiple pbs files are present or .pbs file is not input, set this explictly to the filename
###Identifying 
unless ($inputfile_name)
{
	if ($verbose) {print "Assuming *.pbs file is input file. Edit inputfile_name parameter to change\n";}
	my @pbsfiles;my $input_file;
	opendir(DIR,".") or die "opening directory failed:$!";  
	my @files=readdir(DIR);
	foreach(@files)
	{
		if($_=~/pbs$/) {push @pbsfiles, $_;}
	}
	closedir(DIR);
	$inputfile_name=$pbsfiles[0];
	if (@pbsfiles>1) {print "Multiple pbs files found.\n 
	Rename one or open this script and set the parameter $inputfile_name to the correct file name."; die;}
}

#Reads whole file into scalar inputfile. This will serve as basis later on
open BASE_INPUT, "<", "$inputfile_name" or die "Couldn't open $!";
$inputfile = do { local $/; <BASE_INPUT> };
close BASE_INPUT;

open BASE_INPUT, "<", "$inputfile_name" or print "Couldn't open $!";
while(<BASE_INPUT>) {if (/ATOMIC_POSITIONS {crystal}/ .. /K_POINTS AUTOMATIC/) {push @positions,$_;} }

for (my $i=0; $i < $Li_num; $i++) 
{        $dir[$i]=sprintf("%02s", $i);
        system("mkdir $dir[$i]");

}

foreach $dir (@dir)
{
	$count=0;
	@positions_temp=@positions;
	foreach(@positions_temp)
	{
		if (/Li/) 
		{
			if($count==$dir)
			{
				~s/^\s*Li/#Li/;
			}
			$count++;
		}
		~s/^\s+//;
	}
	$temp_input=$inputfile;
	$temp_input=~ s/ATOMIC_POSITIONS {crystal}.*K_POINTS AUTOMATIC/@positions_temp/sg;
	$temp_input=~ s/[^\S\n]*#Li/#Li/;
	open OUTPUT, ">", "$dir/vacancy.pbs";
	print OUTPUT $temp_input;
	system("cd $dir; qsub vacancy.pbs");
	
	#print "Dir is $dir:\nPostions are @positions_temp";
}



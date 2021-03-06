#!/usr/bin/perl

#I'm not totally sure how this code works. It borrows from the nearest neighbor code, 
#and should output the "interstitial site" (i.e. the site that deviates most strongly from the perfect crystal). 
#It should be run in a directory that contains all of the runs you'd 
#like to investigate in numbered directories of the form 00,01,02...

#Additionally it requires a perfect output file called "perfect_output" to be in the directory the script runs in.

#Output is in the file "output_positions"

#use warnings;
use PDL;
use strict;
use PDL::NiceSlice;
use PDL::Basic;

my @dir;
for (my $i=0;$i<$ARGV[0]+1;$i++) #This should change with the # of sites you're investigating
{
if ($ARGV[0]<100)
{	
	$dir[$i]=sprintf("%02s", $i);
}else{ 
	$dir[$i]=sprintf("%03s", $i);
}}

#open OUTPUT, ">", "output_positions";
foreach my $dire (@dir)
{
#	print "Directory is $dire\n";
	#READS PWSCF OUTPUT(input for this program) into the variable $inputfile
	#print	"$_"."/Li7P3S11.out\n" ;
	unless(open INTERSTITIAL, "<", "$dire"."/Li3PS4.out") {print "$dire failed\n"; next;} 
	#open INTERSTITIAL, "<", "./out" or print "Couldn't open $!";
	
    my @positions;
	my $crystal_cell=pdl;
	my @int_positions;
	my @max_results;

	###########THIS BLOCK DOES FILE I/O#########################
	##########IT STORES THE POSITIONS FOR PERF./INTERSTITIAL RUNS IN 
	##########@positions/@int_positions
	{
		my $alat;
		my @positions_raw;
		my @crystal_axes_raw;
		while(<INTERSTITIAL>) 
		{
			if (/Begin final coordinates/ .. /End final coordinates/) {push @positions_raw,$_;}
			#if (/     Final energy   =/ .. /Writing output data file pwscf.save/) {push @positions_raw,$_;}
			if (/lattice parameter \(alat\)\s+=\s+(\d+\.\d+)/) {$alat=$1}
			if (/crystal axes/ .. /reciprocal axes/) {push @crystal_axes_raw,$_}  #for "relax"
		}

		foreach (@crystal_axes_raw) #for vc-relax?
		{
			if (/\s+(-?\d.\d+\s+-?\d.\d+\s+-?\d.\d+)\s+/) 
			{my $tmp=pdl($1);		
			$crystal_cell=$crystal_cell->glue(1,$tmp)
			}
		}
		if(@positions_raw) {
		$crystal_cell=$crystal_cell->slice(":,1:3");
		$crystal_cell=$crystal_cell*$alat;
		#print $crystal_cell;

		foreach (@positions_raw) 
		{
			if (/Li\s+\-?\d\.\d+/) {push @int_positions, $_}
		}
		#Pulls off the Li and reduces positions to only the coordinates
		foreach (@int_positions) {~ s/Li\s+//}

		#This shifts all the coordinates to be between 0 and 1 (i.e. eliminates negatives)
		#which makes the next piece of code easier to write.

		for(my $i=0;$i<3;$i++) 
		{
			foreach (@int_positions) {if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/e}}
		}
		}
		my $tmp=@int_positions; 
#		print "We have $tmp \(Lithium\) atoms \n";
		$tmp=-1;
		unless(@int_positions)
		 {print "$dire matching failed.\n";}

		@positions_raw={};
	open PERFECT, "<", "perfect_output" or die "Couldn't open $!";
	while(<PERFECT>) {if (/Begin final coordinates/ .. /End final coordinates/) {push @positions_raw,$_;}}

	foreach (@positions_raw) 
		{
			if (/Li\s+\-?\d\.\d+/) {push @positions, $_}
		}
		#Pulls off the Li and reduces positions to only the coordinates
		foreach (@positions) {~ s/Li\s+//}

		#This shifts all the coordinates to be between 0 and 1 (i.e. eliminates negatives)
		#which makes the next piece of code easier to write.

		for(my $i=0;$i<3;$i++) 
		{
			foreach (@positions) {if (/\-\d\.\d+/) {~ s/(\-\d\.\d+)/(1+$1)/e}}
		}

		$tmp=@positions; 
		#print "We have $tmp \(Lithium\) atoms \n";
		$tmp=-1;
		unless(@positions)
		 {print  "Pattern matching failed. Examine input file for perfect run\n"}
	}



	{
		my $num_atoms=@positions;
		my $num_atoms_int=@int_positions;
		my $supersize=27*$num_atoms;;
		my $atom_pos=pdl;
		my $int_atom_pos=pdl;
		my @atom_arrays;

#This brace sets up the scope for the calculation portion of this code, and intializing some scalars in the matrix data type


		################################
		#assigning positions to piddles#
		#################################
		foreach (@positions) #If you're reading from file this can be implemented better using $a=rcols 'filename', [];
		{
			my $temp=pdl($_);
			$atom_pos=$atom_pos->glue(1,$temp);
		}
		#removing zero dimension created by initialization
		$atom_pos=$atom_pos->slice(":,1:$num_atoms");

		foreach(@int_positions)
		{
			my $temp=pdl($_);
			$int_atom_pos=$int_atom_pos->glue(1,$temp);
		}
		#removing zero dimension created by initialization
		$int_atom_pos=$int_atom_pos->slice(":,1:$num_atoms_int");

#		print $int_atom_pos;
#		print $atom_pos;

##########SETS UP A SUPERCELL FOR THE PERFECT STRUCTURE IN CASE INTERSTITIAL SITES ARE ACROSS CRYSTAL BOUNDARIES
		{
			my $supercell_pos=pdl;
			my $zero_col=zeros(1,$num_atoms);
			my $ones_col=ones(1,$num_atoms);
			my $x_shift=$ones_col->glue(0,$zero_col,$zero_col);
			my $y_shift=$zero_col->glue(0,$ones_col,$zero_col);
			my $z_shift=$zero_col->glue(0,$zero_col,$ones_col);
		
			for my $i (qw/ -1 0 1/) #x-loop
			{
				foreach my $j (qw/ -1 0 1/) #y-loop
				{
					foreach my $k (qw/ -1 0 1/)  #z-loop
					{
					my $temp=$atom_pos+$i*$x_shift+$j*$y_shift+$k*$z_shift;
					$supercell_pos=$supercell_pos->glue(1,$temp);
					}
				}
			}
			
		$supercell_pos=$supercell_pos->slice(":,1:$supersize");
		$atom_pos=$supercell_pos;
		}

		my $tmp;
		my $bigtmp;
		for(my $i = 0; $i < $num_atoms_int; $i++) 
		{
			$tmp=$int_atom_pos->slice(":,$i");
			$bigtmp=$tmp;
			for (my $j=0; $j<$supersize-1; $j++) 
			{
				$bigtmp=$bigtmp->glue(1,$tmp);
			}
		push (@atom_arrays, $bigtmp);
		}


		#Here we set up an array, which has as each element the matrix that results when we subtract the position of every atom in our supercell from the position
		#of the given atom.
		#THESE DISTANCES ARE GIVEN IN REAL SPACE COORDINATES
		my @diff_array;
		for (my $i=0; $i<$num_atoms_int; $i++) 
		{
			$diff_array[$i]=transpose($crystal_cell x transpose(($atom_arrays[$i]-$atom_pos)));
		}


		#print $diff_array[0];
		#New variable: an array which will hold array references to the various distances between atoms
		my @all_distances;

		#Now we want to actually find the distance, so we take each position vector (i.e. each row of our matrix) and dot it into its transpose
		my $distance;
		my @distance_array;

		##################################CHANGED
			foreach (@diff_array) 
			{
				for (my $i=0; $i<$supersize; $i++) 
				{	my $distancepdl=sqrt($_->slice(":,$i") x transpose($_->slice(":,$i")));
					#if (1) {my $a=$_->slice(":,$i"); print "$a"};
					$distance=at($distancepdl, (0,0));
					push (@distance_array, $distance);
				}
			push (@all_distances, [@distance_array]);
	#		print "@distance_array\n\n\n";
			@distance_array=();
			}

		my @find_max_array;
		for (my $i=0; $i<@all_distances; $i++) 
		{
			my $temp=$all_distances[$i];
			my @result=&min_element(@$temp);

		#	if ($result[-1]==1)
		#	{
				my $atom_number=$result[1];
				my $modulus=@positions;
#				print "For atom number $i, the minimum distance is $result[0] and the closest atom is number ". $result[1] % $modulus . "\n";

				push(@find_max_array, (-1*$result[0]));

				
		#	} else { print "Atom $i has multiple nearest neighbors\n";}
		}
		
		@max_results=&min_element(@find_max_array);


	}

close INTERSTITIAL;

#print "The interstitial site is site number $max_results[1] with position $int_positions[($max_results[1])]\n";
#print OUTPUT "$dire :$int_positions[($max_results[1])]";
print "$dire $int_positions[($max_results[1])]";
}
#close OUTPUT;


#This subroutine takes an array as input and returns an array with the minimum non-zero value,
#the index or indices where that value occurs, and the # of times it is seen so that
# $return[0]=min and $ret[-1]=number of times min occurs, while the other values are the indices at which min occurs.
sub min_element 
{
	my $min;
	my $count=0;
	my @index_list;
	my $index;
	if (!$min) {$min=$_[0]};
	for(my $i=0; $i<@_; $i++) 
	{
	
	#	if ($_[$i] > 1) 
	#	{	
			if ($_[$i]<$min) 
			{
				$index=$i;
				$min=$_[$i];
			}
	#	}
	}
	for(my $i=0; $i<@_; $i++) 
	{
		if ($_[$i]==$min) 
		{
			push @index_list,$i;$count++;
		}
	}
	my @ret=($min,@index_list,$count);
	@ret;
}


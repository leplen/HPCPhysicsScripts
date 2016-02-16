#!/usr/bin/perl
##############################
# program originally written by Xiao Xu;
#    modified by Yaojun Du and NAWH
##############################
@args=@ARGV;
@args==2 || die "usage: PWscf2Axsf <input> <output>";
open(outputHANDLE,"> $ARGV[1]");
select(outputHANDLE);

#########################################
########to get the lattice parameter#####
#########################################
$au=0.52917720859;
open(scfHANDLE,"$ARGV[0]");
while (<scfHANDLE>){
        if ($_=~/lattice parameter /)
                {
                  @fields=split(" ",$_);
                  $LatticeParameter=$fields[4];
                  #print $LatticeParameter;
                        };
        } ;
$Factor=$au*$LatticeParameter;

##############################################################
########to get the atom number ###############################
######## for practice,number of iter is got with other method#
##############################################################
seek(scfHANDLE,0,0) or die;
while (<scfHANDLE>){
        if ($_=~/number of atoms/)
                {
                  @fields=split(" ",$_);
                   $AtomNumber=$fields[4];

                };
        } ;

#########################################
######the number of iteration########
#########################################

seek(scfHANDLE,0,0) or die;
@Lines=<scfHANDLE>;
$NumberOFIterations=grep(/ATOMIC_POSITIONS/,@Lines);
$NumberOFIterations=$NumberOFIterations;
#print $NumberOFIterations,"\n";;
$CountInitial=$NumberOFIterations;

print "ANIMSTEPS $CountInitial\n";
print "CRYSTAL\n";


#########################################
######the initial coordinates########
#########################################

###########################
## to get the lattice vector######
##########################
seek(scfHANDLE,0,0) or die;

while (<scfHANDLE>){
        if ($_=~/a\(/) {push (@LatticeLine,$_);};

        } ;
#print @LatticeLine,"\n";




#### To get the initial cofiguration#############
print "PRIMVEC  \n";


for($index=0;$index<3;$index++)
        {
                @Letter=split(" ",$LatticeLine[$index]);
                $NumberX=@Letter[3]*$Factor;
                $NumberY=@Letter[4]*$Factor;
                $NumberZ=@Letter[5]*$Factor;
                printf ("%11.7f    %11.7f    %11.7f\n", $NumberX,$NumberY,$NumberZ);
                $LatticeConstant[$index][1]=$NumberX;
                $LatticeConstant[$index][2]=$NumberY;
                $LatticeConstant[$index][3]=$NumberZ;

        }
#print "PRIMCOORD 1\n";
#print "$AtomNumber 1\n";

for($AnimSteps=1;$AnimSteps<$NumberOFIterations+1;$AnimSteps++){
#for($AnimSteps=1;$AnimSteps<3;$AnimSteps++){
        $temp=$AnimSteps;
        print "PRIMCOORD $temp\n";
        print "$AtomNumber 1\n";     
   
seek(scfHANDLE,0,0) or die;
$count=$AnimSteps;

while (<scfHANDLE>){
        if($_=~/ATOMIC_POSITIONS/) {$count--;};
        last if $count==0;
    }
$count=1;

while (<scfHANDLE>){
        $count++;
        push(@CoordLines,$_);
        last if $count>$AtomNumber;
        }

#%ElementTable=(
#                Li=>'3' ,
#                O=>'8'  ,
#                P=>'15' ,
#                Fe=> '26'
#                );

for($index=0;$index<$AtomNumber;$index++){
        ($AtomSym,$CoordX,$CoordY,$CoordZ)=split(" ",$CoordLines[$index]);
        printf ("%s", $AtomSym);
        
        printf ( "%13.8f ", $CoordX*$LatticeConstant[0][1]+$CoordY*$LatticeConstant[1][1]+
    $CoordZ*$LatticeConstant[2][1],);
        printf ( "%13.8f ", $CoordX*$LatticeConstant[0][2]+$CoordY*$LatticeConstant[1][2]+
         $CoordZ*$LatticeConstant[2][2],);
        printf ( "%13.8f ", $CoordX*$LatticeConstant[0][3]+$CoordY*$LatticeConstant[1][3]+
        $CoordZ*$LatticeConstant[2][3],);

        print "\n";
                }

undef @CoordLines;



    }

Program PWscf_triclinic
   Implicit NONE

! Case for triclinic lattice in PWscf pgms where  (according to INPUT_PW.txt)
!ibrav=  14          Triclinic                       celldm(2)= b/a,
!                                                    celldm(3)= c/a,
!                                                    celldm(4)= cos(bc),
!                                                    celldm(5)= cos(ac),
!                                                    celldm(6)= cos(ab)
!    triclinic
!    =============================
!       v1 = (a, 0, 0),
!       v2 = (b*cos(gamma), b*sin(gamma), 0)
!       v3 = (c*cos(beta),  c*(cos(alpha)-cos(beta)cos(gamma))/sin(gamma),
!             c*sqrt( 1 + 2*cos(alpha)cos(beta)cos(gamma)
!                       - cos(alpha)^2-cos(beta)^2-cos(gamma)^2 )/sin(gamma) )
!    where alpha is the angle between axis b and c
!           beta is the angle between axis a and c
!           gamma is the angle between axis a and b
!
!!!!!!!!!!!!!
!   calling sequence:   PWscf_triclinic inputfilename scale=(initial celldm(1))
    CHARACTER(256) :: readline,inputfilename
    REAL(8) :: a(3),b(3),c(3),celldm(6),aa(3),bb(3),cc(3),scale
    REAL(8) :: alen,blen,clen,alpha,beta,gamma,deg
    REAL(8), parameter :: ang=0.52917720859d0
    INTEGER :: iargc ,i   

    call GetArg(1,inputfilename)
    open(7,file=TRIM(inputfilename),form='formatted', status='old')
    scale=1.d0
    if (iargc()>1) then
       call GetArg(2,readline)
       read(readline,*) scale
    endif

    deg=180.d0/acos(-1.d0)
    do
      READ(7,'(a)',iostat=i) readline
           If(i/=0) exit
           If(readline(1:15)=='CELL_PARAMETERS') then
             read(7,*) a
             read(7,*) b
             read(7,*) c
             alen=sqrt(DOT_PRODUCT(a,a))*scale
             blen=sqrt(DOT_PRODUCT(b,b))*scale
             clen=sqrt(DOT_PRODUCT(c,c))*scale
             celldm(1)=alen
             celldm(2)=blen/alen
             celldm(3)=clen/alen
             celldm(4)=(DOT_PRODUCT(b,c)/&
                  sqrt((DOT_PRODUCT(b,b))*(DOT_PRODUCT(c,c))))
             celldm(5)=(DOT_PRODUCT(a,c)/&
                  sqrt((DOT_PRODUCT(a,a))*(DOT_PRODUCT(c,c))))
             celldm(6)=(DOT_PRODUCT(b,a)/&
                  sqrt((DOT_PRODUCT(b,b))*(DOT_PRODUCT(a,a))))
             alpha=acos(celldm(4));beta=acos(celldm(5));gamma=acos(celldm(6))
             aa=0; aa(1)=alen
             bb=0; bb(1)=blen*cos(gamma); bb(2)=blen*sin(gamma)
             cc=0; cc(1)=clen*cos(beta)
             cc(2)=clen*(cos(alpha)-cos(beta)*cos(gamma))&
                     /sin(gamma)
             cc(3)=clen*sqrt(1.d0+ &
                     2*cos(alpha)*cos(beta)*cos(gamma)&
                - cos(alpha)**2-cos(beta)**2-cos(gamma)**2 )&
                      /sin(gamma) 
           ENdif
     enddo

     Write(6,*) ' Last recorded lattice parameters:'

        write(6,'( "                 a = ", 3f20.8)') a
        write(6,'( "                 b = ", 3f20.8)') b
        write(6,'( "                 c = ", 3f20.8)') c
        write(6, '( )')
        write(6,'( "                 A = ", 3f20.8)') aa
        write(6,'( "                 B = ", 3f20.8)') bb
        write(6,'( "                 C = ", 3f20.8)') cc
        write(6,'( "  alpha,beta,gamma: ", 3f20.8)') alpha*deg,beta*deg,&
                      gamma*deg
         write(6,'( "              alat = ", f20.8)') scale
         write(6,'( "         celldm(1) = ", f20.8",")')  celldm(1)
         write(6,'( "         celldm(2) = ", f20.8",")')  celldm(2)
         write(6,'( "         celldm(3) = ", f20.8",")')  celldm(3)
         write(6,'( "         celldm(4) = ", f20.8",")')  celldm(4)
         write(6,'( "         celldm(5) = ", f20.8",")')  celldm(5)
         write(6,'( "         celldm(6) = ", f20.8",")')  celldm(6)
         write(6,'( "Lattice parameters = ", 3f20.8)') alen,blen,clen
         write(6,'( "Angstrom lattice  = ", 3f20.8)') alen*ang,&
                         blen*ang,clen*ang
  End program

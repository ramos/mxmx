

Program mmtest
!
! Example of use of MIXMAX RNG. For more information have a look at: 
!
! (*) The MIXMAX random number generator
!     Konstantin G. Savvidy (http://arxiv.org/abs/1403.5355)
!
! (*) https://mixmax.hepforge.org/ (mixmax_release_100_beta.zip)
!

  USE MIXMAX
  USE ISO_FORTRAN_ENV, Only : iostat_end, output_unit

  IMPLICIT NONE

  Real (kind=8) :: dsc, dvec(11)
  Complex (kind=8) :: zvec(8)
  Character (len=20) :: fn='mxmx_magic.dat'
  Integer :: I, jj, nmx = 256, i2, ios

  Integer (kind=8) :: i8(1)
  Integer (kind=8), allocatable :: array(:,:)
  logical :: setted = .False.

  ! As with almost any RNG the steps are always the same:
  ! Initialize, seed and get random numbers
  !
  ! 1) To initialize MIXMAX one needs to call 
  !    mxmx_init(int32) with the matrix size as input parameters.
  !    Valid matrix sizes are: 
  !    3150 1260 1000 720 508 256 (default) 88 64 44 40 30 16 10
  !    88 or anything bigger should do any job (they all passed the
  !    BigCrush). The speed is independent of this number.
  CALL mxmx_init(Nmx)             

  ! 2) Seed the RNG. There are four available methods:
  !    o mxmx_seed_skip(ids_int32(4)): Seed with an array of up 
  !      to 4 integers (e.g. (/ clusterID, machineID, runID, MPIprocID/) ). 
  !      as an array. Mathematically guaranteed that if at least a 
  !      single bit of any of the 4 numbers is different, then 
  !      the different streams will not collide. This is the 
  !      perfect seeding method, but needs access to the 
  !      precomputed coefficients (look at the file mxmx_magic.dat
  !      and the routine Read_skiparray_from_file() at the end
  !      of this main program)
  Allocate(array(0:127,Nmx))      ! Read the array for skip
  CALL Read_skiparray_from_file() ! Look at the end of the main
  CALL mxmx_set_skip(array)       ! Set the skip array
  CALL mxmx_seed_skip((/626521, 8234567, 34657832, 306745/)) ! Bigskip
  CALL mxmx_free_skip() ! Once seeded, we can free memory if we want

  !    o mxmx_seed_spbox(int64): As good as "traditional" seeding. 
  !      Very unlikely that different seeds collide.
!  CALL mxmx_seed_spbox(250032065_8) ! spbox

  !    o mxmx_seed_lcg(int64): Another traditional seeding, but 
  !      different seeds can collide. Use reative prime seeds
  !      to avoid this (I could be understanding something wrong 
  !      here!).
!  CALL mxmx_seed_lcg(235634634_8) 

  !    o mxmx_seed_vielbein(int32): Seed with unit vector. Mainly 
  !      for test. 
!  CALL mxmx_seed_vielbein(1)


  ! At any moment we can print the status of the RNG. Use an opened 
  ! unit number as argument if you want to write to a file
  CALL mxmx_print_info(output_unit)
 
  
  ! 3) Get numbers with calls to mxmx. It will fill with RN
  !    either scalars or vectors of any intrinsic type 
  CALL mxmx(dsc)
  CALL mxmx(dsc)
  CALL mxmx(dsc)
  Do jj = 1, 2
     CALL mxmx(dvec(1:size(dvec)))
     Write(*,'(1I4,1ES25.18)')(I, dvec(I), I=1,size(dvec))
  End Do
  Write(*,*)
  Write(*,*)
  CALL mxmx_print_info()
  
  !    Also complex valued arrays
  CALL mxmx(zvec(1:size(zvec)))
  Write(*,'(1I4,2ES25.18)')(I, zvec(I), I=1,size(zvec))
  Write(*,*)
  CALL mxmx_print_info()

  Stop
CONTAINS

  Subroutine Read_skiparray_from_file() 
    
    ! The file mxmx_magic.dat contains int64 integers in 
    ! little endian format. If your are running a big endian 
    ! machine  do the byteswap yourself

    Open(Unit=88, File=Trim(fn), ACTION="READ", &
         & Form='UNFORMATTED', Access='STREAM')
    Do 
       Read(88, iostat=ios)i8(1)
       If (ios == iostat_end) Exit
       If (i8(1) == int(Nmx,kind=8)) Then
          setted = .True.
          Do I2 = 0, 127
             Read(88)array(I2,:)
          End Do
       Else
          Do I2 = 1, Int(i8(1),kind=4)
             Read(88)array(0:127,I2)
          End Do
       End if
    End Do

    If (setted) Then
       Write(*,*)'Readed skip matrix from: ', Trim(fn)
    Else
       Write(*,*)'skip matrix not found in: ', Trim(fn)
    End If

    close(88)
    Return
  End Subroutine Read_skiparray_from_file
  
End Program mmtest



Program mmtest
!
! Example of use of MIXMAX RNG with openMP.  
! For more information have a look at: 
!
! (*) The MIXMAX random number generator
!     Konstantin G. Savvidy (http://arxiv.org/abs/1403.5355)
!
! (*) https://mixmax.hepforge.org/ (mixmax_release_100_beta.zip)
!

  USE omp_lib
  USE MIXMAX
  USE ISO_FORTRAN_ENV, Only : iostat_end, output_unit

  IMPLICIT NONE

  Real (kind=8) :: dsc
  Character (len=20) :: fn='mxmx_magic.dat'
  Integer :: nmx = 256, i2, ios
  Integer, save :: IDthread

  Integer (kind=8) :: i8(1)
  Integer (kind=8), allocatable :: array(:,:)
  logical :: setted = .False.

  !$OMP THREADPRIVATE(IDthread)

  ! With openMP we need to initialize the RNG inside an 
  ! OMP directive. We also get the thread id that later will
  ! use for seeding

  !$OMP PARALLEL 
  IDthread = OMP_GET_THREAD_NUM()
  Write(*,*)'Hello from proc: ', IDthread
  CALL mxmx_init(Nmx)
  !$OMP END PARALLEL

  Allocate(array(0:127,Nmx))      ! Read the array for skip
  CALL Read_skiparray_from_file() ! Look at the end of the main
  CALL mxmx_set_skip(array)       ! Set the skip array

  ! Seed using skip with the IDthread. This will 
  ! guarantee that different streams do not collide

  !$OMP PARALLEL
  CALL mxmx_seed_skip((/626521, 8234567, 34657832, 306745+IDthread/)) ! Bigskip
  !$OMP END PARALLEL
  CALL mxmx_free_skip() ! Once seeded, we can free memory if we want


  ! Generate one random number in each thread, print it, and 
  ! print the status of MIXMAX

  !$OMP PARALLEL PRIVATE(dsc)
  CALL mxmx(dsc)
  Write(*,*)'Process: ', IDthread, ' random number: ', dsc
  CALL mxmx_print_info(output_unit)
  !$OMP END PARALLEL
 
  

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





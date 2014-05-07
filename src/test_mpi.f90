

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

  USE MPI
  USE MIXMAX
  USE ISO_FORTRAN_ENV, Only : iostat_end, output_unit

  IMPLICIT NONE

  Real (kind=8) :: dsc
  Character (len=20) :: fn='mxmx_magic.dat'
  Integer :: nmx = 256, i2, ios
  Integer :: IDproc, Nproc, Ierr

  Integer (kind=8) :: i8(1)
  Integer (kind=8), allocatable :: array(:,:)
  logical :: setted = .False.

  ! With MPI we need to initialize the RNG for each MPI
  ! process. We get the proc id that later will use for seeding
  CALL MPI_Init(Ierr)
  CALL MPI_Comm_rank(MPI_COMM_WORLD, IDproc, Ierr)
  CALL MPI_Comm_size(MPI_COMM_WORLD, Nproc, Ierr)
  CALL mxmx_init(Nmx)

  ! The skip array is readed by proc 0, and broadcasted to the
  ! others, conforming MPI standards.
  Allocate(array(0:127,Nmx))      ! Read the array for skip
  If (IDproc == 0) Then
     CALL Read_skiparray_from_file() ! Look at the end of the main
  End If
  CALL MPI_BCAST(array,nmx*128,MPI_INTEGER8,0,MPI_COMM_WORLD, Ierr)
  CALL mxmx_set_skip(array)       ! Set the skip array in all process

  ! Seed using skip with the IDproc. This will guarantee 
  ! that different process do not collide and produde 
  ! independent results.
  CALL mxmx_seed_skip((/626521, 8234567, 34657832, 306745+IDproc/))
  CALL mxmx_free_skip() ! Once seeded, we can free memory if we want


  ! Generate one random number in each process, print it, and 
  ! print the status of MIXMAX. 
  CALL mxmx(dsc)
  Write(*,*)'Process: ', IDproc, ' random number: ', dsc
  CALL mxmx_print_info(output_unit)

  CALL MPI_Finalize(Ierr)

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







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

  Real (kind=8) :: dsc, dvec(100)
  Complex (kind=8) :: zvec(8)
  Character (len=20) :: fn='mxmx_magic.dat'
  Integer :: I, jj, nmx = 256, i2, ios

  Integer (kind=8) :: i8(1)
  Integer (kind=8), allocatable :: array(:,:)
  logical :: setted = .False.

  CALL mxmx_init(256)
  CALL mxmx_seed_spbox(250032065_8) ! spbox
  Do jj = 1, 20000000
     CALL mxmx(dvec)
  End Do

  CALL mxmx(dsc)
  Write(*,*)jj, dsc
  CALL mxmx_print_info(output_unit)
 
  
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

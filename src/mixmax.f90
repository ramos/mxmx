!
! A MODULE for MIXMAX Random Number Generator
!
! This module implements the MIXMAX Random Number Generator in 
! standard fortran 2008. The relevant references are:
!
! (*) On the Monte Carlo Simulation of Physical Systems
!     J.Comput.Phys. 97, 566 (1991)
!
! (*) Matrix Generator of Pseudorandom Numbers 
!     J.Comput.Phys.97, 573 (1991).
!
! (*) The MIXMAX random number generator
!     Konstantin G. Savvidy (http://arxiv.org/abs/1403.5355)
!
! This implementation is heavily based (i.e. routines are a copy) on 
! the C implementation that can be found in 
!
! https://mixmax.hepforge.org/ (mixmax_release_100_beta.zip)
!
! The code has been compared with this reference implementation,
! but as always the correctness of the code can not be guaranteed. 
! Use with caution.
!
! "THE BEER-WARE LICENSE":
! Alberto Ramos wrote this file. As long as you retain this 
! notice you can do whatever you want with this stuff. If we meet some 
! day, and you think this stuff is worth it, you can buy me a beer in 
! return. <alberto.ramos@desy.de>
!
! $ v1.0 20140429 $

! ***************************************************
! *
MODULE MixMax
! *
! ***************************************************

  ! For openMP. If this gives any problem/error (i.e. your compiler
  ! does not support openMP), simply comment this line. Non
  ! openMP and mpi programs should work.
  USE omp_lib

  USE ISO_FORTRAN_ENV, Only : error_unit, output_unit
  IMPLICIT NONE

  Type, Private :: State
     Integer (kind=4) :: N
     Integer (kind=8), Allocatable :: V(:)
     Integer (kind=4) :: cnt
     Integer (kind=8) :: sumtot = 0_8, cyc = 0_8
     
     Integer (kind=4) :: skipsd(4) = -1, SEED_TYPE = -1
     Integer (kind=8) :: otherseed = -1_8
  End type State

  Interface 
     Function Mulspec(nin)
       Integer (kind=8), Intent (in) :: nin
       Integer (kind=8) :: Mulspec
     End Function Mulspec
  End Interface

  Interface mxmx
     Module Procedure mxmx_int, mxmx_f64, mxmx_f32, mxmx_f64_v, &
          & mxmx_f32_v, mxmx_z64, mxmx_z32, mxmx_z64_v, mxmx_z32_v, &
          & mxmx_int_v
  End Interface mxmx

  Type (State), private, save :: rnd

  Procedure (Mulspec), Pointer, Private :: Mod_Mulspec => null()!noinit

  Integer (kind=8), Parameter, Private :: &
       & MULT=1073217536_8, BITS = 61_8, MERSBASE = 2305843009213693951_8
  Integer (kind=8), Private :: SPECIAL
  
  Integer (kind=8), Allocatable, Private :: skip(:,:)
  Real (kind=8), Parameter :: DINV_MERSBASE=0.433680868994201773791060216479542685926876E-18_8

  Logical, Private :: is_skip_loaded = .False., is_init = .False.

  Integer, Parameter, Private :: SEED_LCG=0, SEED_SKIP=1, &
       & SEED_VI=2, SEED_SPBOX=3

  Private :: noinit, mxmx_int, mxmx_f64, fill_rnd, Mod_Mersenne, &
       & Mod_Mulspec_direct, Mod_Mulspec_default, Mod_Mulspec_zero, &
       & Mod_Mulspec_one, mxmx_error, mxmx_f64_v, mxmx_f32, mxmx_int_v, &
       & mxmx_f32_v, mxmx_z64, mxmx_z32, mxmx_z64_v, mxmx_z32_v


  !$OMP THREADPRIVATE(rnd,is_init)

CONTAINS

! ***************************************************
! *
  Subroutine mxmx_init(nin)
! *
! ***************************************************

    Integer, Intent (in), Optional :: nin
    Integer :: nmat

    If (Present(nin)) Then
       nmat = nin
    Else
       nmat = 256
    End If
    
    Allocate(rnd%V(nmat))
    rnd%N = nmat
    Select Case (nmat)
    Case (1260)
       SPECIAL = 15_8
    Case (3150)
       SPECIAL = -11_8
    Case (1000)
       SPECIAL = 0_8
    Case (720)
       SPECIAL = 1_8
    Case (508)
       SPECIAL = 5_8
    Case (256)
       SPECIAL = -1_8
    Case (88)
       SPECIAL = 1_8
    Case (64)
       SPECIAL = 6_8
    Case (44)
       SPECIAL = 0_8
    Case (40)
       SPECIAL = 1_8
    Case (30)
       SPECIAL = 3_8
    Case (16)
       SPECIAL = 6_8
    Case (10)
       SPECIAL = -1_8
    Case Default
       CALL mxmx_error('mxmx_init', 'Possible values for N are: '//&
            &'3150 1260 1000 720 508 256 (default) 88 64 44 40 30 16 10')
    End Select

    Select Case (SPECIAL)
    Case (2:3)
       Mod_Mulspec => Mod_MulSpec_direct
    Case (-3:-2)
       Mod_Mulspec => Mod_MulSpec_minusdirect
    Case (1)
       Mod_Mulspec => Mod_MulSpec_one
    Case (-1)
       Mod_Mulspec => Mod_MulSpec_minusone
    Case (0)
       Mod_Mulspec => Mod_MulSpec_zero
    Case Default
       Mod_Mulspec => Mod_MulSpec_default
    End Select
    rnd%cnt=1
    is_init = .True.

    If (nmat < 88) Then
       Write(error_unit,'(1A,1I4)')'**WARNING** MIXMAX Working with a matrix size that is known not to pass all statistical tests '
       Write(error_unit,'(1A,1I6)')'MIXMAX Matrix size: ', rnd%N
    End If

    Return
  End Subroutine mxmx_init

! ***************************************************
! *
  Subroutine mxmx_seed_lcg(nseed)
! *
! ***************************************************
    
    Integer (kind=8), Intent (in) :: nseed
    Integer :: I


    If (nseed == 0_8) CALL mxmx_error('mxmx_seed_lcg', &
         & 'Seed must be bigger than 0')

    rnd%sumtot = 0_8
    rnd%V(1) = iand(nseed,MERSBASE)
    rnd%sumtot = 0_8
    Do I = 2, rnd%N
       rnd%V(I) = modmulM61(rnd%V(I-1), MULT)
       rnd%sumtot = Mod_Mersenne(rnd%V(I)+rnd%sumtot)
    End Do
    rnd%cnt = 1

    rnd%SEED_TYPE = SEED_LCG
    rnd%otherseed = nseed
    rnd%skipsd = -1

    Return
  End Subroutine mxmx_seed_lcg

! ***************************************************
! *
  Subroutine mxmx_seed_spbox(nseed)
! *
! ***************************************************
    
    Integer (kind=8), Intent (in) :: nseed
    Integer (kind=8), Parameter :: MULT64=6364136223846793005_8
    Integer (kind=8)  :: l
    Integer :: I

    If (nseed == 0_8) CALL mxmx_error('mxmx_seed_spbox', &
         & 'Seed must be bigger than 0')

    rnd%sumtot = 0_8
    rnd%V(1) = iand(nseed,MERSBASE)
    l = nseed
    Do I = 2, rnd%N
       l = l*MULT64
       l = ieor(ishft(l,32), ishft(l,-32))
       rnd%V(I) = iand(l, MERSBASE)
       rnd%sumtot = Mod_Mersenne(rnd%V(I)+rnd%sumtot)
    End Do
    rnd%cnt = 1

    rnd%SEED_TYPE = SEED_SPBOX
    rnd%otherseed = nseed
    rnd%skipsd = -1

    Return
  End Subroutine mxmx_seed_spbox

! ***************************************************
! *
  Subroutine mxmx_seed_vielbein(nidx)
! *
! ***************************************************
    
    Integer, Intent (in), Optional :: nidx

    If (present(nidx)) Then
       If (nidx > rnd%N) CALL mxmx_error("mxmx_seed_vielbein", &
            & 'index out of range')
       rnd%V(1:nidx-1) = 0_8
       rnd%V(nidx+1:)  = 0_8
       rnd%V(nidx)     = 1_8
       rnd%otherseed   = nidx
    Else
       rnd%V(2:)     = 0_8
       rnd%V(1)      = 1_8
       rnd%otherseed = 1
    End If
    rnd%cnt    = rnd%N+1
    rnd%sumtot = 0_8
    rnd%cyc    = -1_8

    rnd%SEED_TYPE = SEED_VI
    rnd%skipsd    = -1 

    Return
  End Subroutine mxmx_seed_vielbein

! ***************************************************
! *
  Subroutine mxmx_seed_skip(ids)
! *
! ***************************************************
    
    Integer, Intent (in) :: ids(:)

    If (.not.is_skip_loaded) CALL mxmx_error('mxmx_skip', &
         & 'Array with magic numbers not loaded')

    CALL mxmx_seed_vielbein()
    CALL mxmx_big_skip(ids)
    rnd%cnt = rnd%N+1
    rnd%cyc = -1_8

    rnd%SEED_TYPE = SEED_SKIP
    rnd%skipsd = ids
    rnd%otherseed = -1_8

    Return
  End Subroutine mxmx_seed_skip

! ***************************************************
! *
  Subroutine mxmx_set_skip(ar)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: ar(0:,1:)

    If (.not.is_init) CALL mxmx_error('mxmx_set_skip', &
         &'MIXMAX has to be initialized first')
    if (Size(ar,1) /= 128) CALL mxmx_error('mxmx_set_skip', &
         &'Incorrect skip matrix')
    if (Size(ar,2) /= rnd%N) CALL mxmx_error('mxmx_set_skip', &
         &'Incorrect skip matrix')

    ALLOCATE(skip(0:127,rnd%N))
    skip(0:,1:) = ar(0:,1:)
    is_skip_loaded = .True.

    Return
  End Subroutine mxmx_set_skip

! ***************************************************
! *
  Subroutine mxmx_free_skip()
! *
! ***************************************************

    If (.not.is_init) CALL mxmx_error('mxmx_free_skip', &
         &'MIXMAX has to be initialized first')
    DeALLOCATE(skip)
    is_skip_loaded = .False.

    Return
  End Subroutine mxmx_free_skip

! ***************************************************
! *
  Subroutine mxmx_big_skip(ids)
! *
! ***************************************************
    
    Integer, Intent (in) :: ids(:)
    Integer :: nids, id, j, ir, idnx, i
    Integer (kind=8), Allocatable :: cum(:)

    If (.not.is_skip_loaded) CALL mxmx_error('mxmx_big_skip', &
         & 'Array with magic numbers not loaded')
    nids = Size(ids)
    If (nids > 4) CALL mxmx_error("mxmx_big_skip", &
         & "Uffff... I do not know how to skip so much (max: 4 integers)")

    Allocate(cum(rnd%N))
    Do idnx = 0, nids-1
       id = ids(nids-idnx)
       ir = 0
       Do While (id > 0)
          If (Modulo(id,2) == 1) Then
             cum = 0_8
             Do J = 1, rnd%N
                Do I = 1, rnd%N
                   cum(I) = Mod_Mersenne( cum(i) + &
                        & modmulM61(skip(ir+idnx*32,J),rnd%V(I)))
                End Do
                CALL fill_rnd()
             End Do
             
             rnd%V(:) = cum(:)
             rnd%sumtot = 0_8
             Do j = 2, rnd%N
                rnd%sumtot = Mod_Mersenne(rnd%sumtot + rnd%V(j))
             End Do
          End If
          id = ishft(id,-1)
          ir = ir + 1
       End Do
    End Do
    Deallocate(cum)
    Return
  End Subroutine mxmx_big_skip

! ***************************************************
! *
  Subroutine mxmx_print_info(ifn)
! *
! ***************************************************

    Integer, Intent (in), Optional :: ifn
    Integer :: iout     
    
    iout = output_unit
    if (present(ifn)) iout = ifn

    Write(iout,'(1A,1I4)')'MIXMAX Working in the Galois field with modulus 2^61-1'
    Write(iout,'(1A,1I6)')'MIXMAX Matrix size: ', rnd%N
    Write(iout,'(1A)', ADVANCE="NO")'MIXMAX seeded with method: '

    Select Case (rnd%SEED_TYPE)
    Case (SEED_VI)
       Write(iout,'(1A)', ADVANCE="NO")'seed vielbein ('
       Write(iout,'(1I11,1A)')rnd%otherseed, ' )'
    Case (SEED_LCG)
       Write(iout,'(1A)', ADVANCE="NO")'seed LCG'
       Write(iout,'(1I11,1A)')rnd%otherseed, ' )'
    Case (SEED_SPBOX)
       Write(iout,'(1A)', ADVANCE="NO")'seed spbox ('
       Write(iout,'(1I11,1A)')rnd%otherseed, ' )'
    Case (SEED_SKIP)
       Write(iout,'(1A)', ADVANCE="NO")'seed skip ('
       Write(iout,'(4I11,1A)')rnd%skipsd(:), ' )'
    End Select
    Write(iout,'(1A,1I22,1A)')'MIXMAX since seeded generated: ', &
         & Max( Int(rnd%N,kind=8)*rnd%cyc + &
         &      Modulo(int(rnd%cnt,kind=8),Int(rnd%N,kind=8))-1,0_8), &
         & ' random numbers' 

    Return
  End Subroutine mxmx_print_info

! ***************************************************
! *
  Subroutine mxmx_int(n)
! *
! ***************************************************

    Integer (kind=8), Intent (out) :: n
    Integer (kind=4) :: ipos
    
    ipos = rnd%cnt
    If (ipos > rnd%N) Then
       ipos = 1
       CALL fill_rnd()
    End If
    rnd%cnt = rnd%cnt + 1
    n = rnd%V(ipos)

    Return
  End Subroutine mxmx_int

! ***************************************************
! *
  Subroutine mxmx_int_v(n)
! *
! ***************************************************

    Integer (kind=8), Intent (out) :: n(:)
    Integer (kind=4) :: i, nleft, nst, ncyc
    
    nleft = Size(n)
    nst = rnd%N-rnd%cnt+1
    If (nst > nleft) Then
       n(1:nleft) = rnd%V(rnd%cnt:rnd%cnt+nleft-1) 
       rnd%cnt = rnd%cnt+nleft
       Return
    Else
       n(1:nst) = rnd%V(rnd%cnt:rnd%cnt+nst-1)
       nleft = nleft - nst
    End If
    CALL fill_rnd() 
    
    ncyc = Int(nleft/rnd%N)
    Do I = 1, ncyc
       n(nst+1+(I-1)*rnd%N:nst+I*rnd%N) = rnd%V(1:rnd%N)
       CALL fill_rnd()
    End Do
    nleft = Modulo(nleft,rnd%N)
    n(nst+1+ncyc*rnd%N:Size(n)) = rnd%V(1:nleft)
    rnd%cnt = nleft+1

    Return
  End Subroutine mxmx_int_v

! ***************************************************
! *
  Subroutine mxmx_f64(d)
! *
! ***************************************************

    Real (kind=8), Intent (out) :: d
    Integer (kind=4) :: ipos
    
    ipos = rnd%cnt
    If (ipos > rnd%N) Then
       ipos = 1
       CALL fill_rnd()
    End If
    rnd%cnt = rnd%cnt + 1
    d = Real(rnd%V(ipos),kind=8)*DINV_MERSBASE

    Return
  End Subroutine mxmx_f64

! ***************************************************
! *
  Subroutine mxmx_z64(d)
! *
! ***************************************************

    Complex (kind=8), Intent (out) :: d
    Real (kind=8) :: x, y

    CALL mxmx(x)
    CALL mxmx(y)
    d = Cmplx(x,y,kind=8)
    
    Return
  End Subroutine mxmx_z64

! ***************************************************
! *
  Subroutine mxmx_z32(d)
! *
! ***************************************************

    Complex (kind=4), Intent (out) :: d
    Real (kind=4) :: x, y

    CALL mxmx(x)
    CALL mxmx(y)
    d = Cmplx(x,y)
    
    Return
  End Subroutine mxmx_z32

! ***************************************************
! *
  Subroutine mxmx_f64_v(d)
! *
! ***************************************************

    Real (kind=8), Intent (out) :: d(:)
    Integer (kind=4) :: i, nleft, nst, ncyc
    
    nleft = Size(d)
    nst = rnd%N-rnd%cnt+1
    If (nst > nleft) Then
       d(1:nleft) = Real(rnd%V(rnd%cnt:rnd%cnt+nleft-1),kind=8)&
            & * DINV_MERSBASE
       rnd%cnt = rnd%cnt+nleft
       Return
    Else
       d(1:nst) = Real(rnd%V(rnd%cnt:rnd%cnt+nst-1),kind=8) &
            & * DINV_MERSBASE
       nleft = nleft - nst
    End If
    CALL fill_rnd() 
    
    ncyc = Int(nleft/rnd%N)
    Do I = 1, ncyc
       d(nst+1+(I-1)*rnd%N:nst+I*rnd%N) = &
            & Real(rnd%V(1:rnd%N),kind=8)*DINV_MERSBASE
       CALL fill_rnd()
    End Do
    nleft = Modulo(nleft,rnd%N)
    d(nst+1+ncyc*rnd%N:Size(d)) = &
         & Real(rnd%V(1:nleft),kind=8)*DINV_MERSBASE
    rnd%cnt = nleft+1

    Return
  End Subroutine mxmx_f64_v

! ***************************************************
! *
  Subroutine mxmx_z64_v(d)
! *
! ***************************************************

    Complex (kind=8), Intent (out) :: d(:)
    Real (kind=8) :: x(Size(d))
    
    CALL mxmx(x)
    d = Cmplx(x,0.0_8,kind=8)
    CALL mxmx(x)
    d = d + Cmplx(0.0_8,x,kind=8)

    Return
  End Subroutine mxmx_z64_v

! ***************************************************
! *
  Subroutine mxmx_z32_v(d)
! *
! ***************************************************

    Complex (kind=4), Intent (out) :: d(:)
    Real (kind=4) :: x(Size(d))
    
    CALL mxmx(x)
    d = Cmplx(x,0.0_4)
    CALL mxmx(x)
    d = d + Cmplx(0.0_4,x)

    Return
  End Subroutine mxmx_z32_v

! ***************************************************
! *
  Subroutine mxmx_f32_v(d)
! *
! ***************************************************

    Real (kind=4), Intent (out) :: d(:)
    Integer (kind=4) :: i, nleft, nst, ncyc
    
    nleft = Size(d)
    nst = rnd%N-rnd%cnt+1
    If (nst > nleft) Then
       d(1:nleft) = Real(rnd%V(rnd%cnt:rnd%cnt+nleft-1),kind=4)&
            & * Real(DINV_MERSBASE,kind=4)
       rnd%cnt = rnd%cnt+nleft
       Return
    Else
       d(1:nst) = Real(rnd%V(rnd%cnt:rnd%cnt+nst-1),kind=4) &
            & * Real(DINV_MERSBASE,kind=4)
       nleft = nleft - nst
    End If
    CALL fill_rnd() 
    
    ncyc = Int(nleft/rnd%N)
    Do I = 1, ncyc
       d(nst+1+(I-1)*rnd%N:nst+I*rnd%N) = &
            & Real(rnd%V(1:rnd%N),kind=4)*Real(DINV_MERSBASE,kind=4)
       CALL fill_rnd()
    End Do
    nleft = Modulo(nleft,rnd%N)
    d(nst+1+ncyc*rnd%N:Size(d)) = &
         & Real(rnd%V(1:nleft),kind=4)*Real(DINV_MERSBASE,kind=4)
    rnd%cnt = nleft+1

    Return
  End Subroutine mxmx_f32_v

! ***************************************************
! *
  Subroutine mxmx_f32(d)
! *
! ***************************************************

    Real (kind=4), Intent (out) :: d
    Integer (kind=4) :: ipos
    
    ipos = rnd%cnt
    If (ipos > rnd%N) Then
       ipos = 1
       CALL fill_rnd()
    End If
    rnd%cnt = rnd%cnt + 1
    d = Real(Real(rnd%V(ipos),kind=8)*DINV_MERSBASE,kind=4)

    Return
  End Subroutine mxmx_f32

! ***************************************************
! *
  Subroutine fill_rnd()
! *
! ***************************************************

    Integer (kind=8) :: tmpV, tmpP, oldsumtot, I, tmp2
    
    rnd%cnt = 1_8
    If (SPECIAL /= 0_8) tmp2 = rnd%V(2)

    oldsumtot  = rnd%sumtot
    rnd%sumtot = 0_8 
    tmpV = Mod_Mersenne(rnd%V(1) + oldsumtot)
    tmpP = 0
    rnd%V(1) = tmpV
    Do I = 2, rnd%N
       tmpP = Mod_Mersenne(rnd%V(I) + tmpP)
       tmpV = Mod_Mersenne(tmpV + tmpP)
       rnd%V(I) = tmpV
       rnd%sumtot = Mod_Mersenne(rnd%sumtot + tmpV)
    End Do

    If (SPECIAL /= 0_8) Then
       tmp2 = Mod_MulSpec(tmp2)
       rnd%V(3) = Mod_Mersenne(rnd%V(3) + tmp2)
       rnd%sumtot = Mod_Mersenne(rnd%sumtot + tmp2)
    End If
    rnd%cyc = rnd%cyc + 1

    Return
  End Subroutine fill_rnd

! ***************************************************
! *
  Function Mod_Mersenne(nin)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mersenne
    
    Mod_Mersenne = iand(nin,MERSBASE) + ishft(nin, -BITS)

    Return
  End Function Mod_Mersenne

! ***************************************************
! *
  Function Mod_Mulspec_direct(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    Mod_Mulspec = Mod_Mersenne(SPECIAL*nin)

    Return
  End Function Mod_Mulspec_direct

! ***************************************************
! *
  Function Mod_Mulspec_minusdirect(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    Mod_Mulspec = MERSBASE - Mod_Mersenne(-SPECIAL*nin)

    Return
  End Function Mod_Mulspec_minusdirect

! ***************************************************
! *
  Function Mod_Mulspec_default(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    If (SPECIAL < 0) Then
       Mod_Mulspec = MERSBASE - modmulM61(nin,-SPECIAL)
    Else
       Mod_Mulspec = modmulM61(nin,SPECIAL)
    End If

    Return
  End Function Mod_Mulspec_default

! ***************************************************
! *
  Function Mod_Mulspec_zero(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    Mod_Mulspec = nin
    Mod_Mulspec = 0_8

    Return
  End Function Mod_Mulspec_zero

! ***************************************************
! *
  Function Mod_Mulspec_one(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    Mod_Mulspec = nin

    Return
  End Function Mod_Mulspec_one

! ***************************************************
! *
  Function Mod_Mulspec_minusone(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    Mod_Mulspec = MERSBASE - nin

    Return
  End Function Mod_Mulspec_minusone

! ********************************
! *
    Subroutine mxmx_error(routine, msg)
! *
! ********************************

      Character (len=*), Intent (in) :: routine, msg

      Write(error_unit,*)'In '//Trim(routine)// ' :'
      Write(error_unit,'(5X,1A)')Trim(msg)
      Write(error_unit,*)

      Stop
      
      Return
    End Subroutine Mxmx_error

! ***************************************************
! *
  Function noinit(nin) Result (Mod_Mulspec)
! *
! ***************************************************

    Integer (kind=8), Intent (in) :: nin
    Integer (kind=8) :: Mod_Mulspec
    
    Mod_Mulspec = -nin
    CALL mxmx_error('rnd state', 'Need to initialize MIXMAX with mxmx_init')

    Return
  End Function Noinit

! ***************************************************
! *
  Function modmulM61(ia,ib) 
! *
! ***************************************************

    Integer (kind=8 ), Intent (in) :: ia, ib
    Integer (kind=8) :: modmulM61, ica, icb
    
    ica = ia
    icb = ib
    modmulM61 = 0_8
    Do While (icb > 0_8)
       if (iand(icb,1_8)==1_8) Then
          modmulM61 = Mod_Mersenne(modmulM61 + ica)
       End if
       ica = Mod_Mersenne(ishft(ica,1))
       icb = ishft(icb,-1)
    End Do

    Return
  End Function modmulM61

End MODULE MixMax

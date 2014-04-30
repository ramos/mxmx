
A MODULE for MIXMAX Random Number Generator

This module implements the MIXMAX Random Number Generator in 
standard fortran 2008. The relevant references are:

(*) On the Monte Carlo Simulation of Physical Systems
    J.Comput.Phys. 97, 566 (1991)

(*) Matrix Generator of Pseudorandom Numbers 
    J.Comput.Phys.97, 573 (1991).

(*) The MIXMAX random number generator
    Konstantin G. Savvidy (http://arxiv.org/abs/1403.5355)

This implementation is heavily based (i.e. routines are a copy) of 
the C implementation that can be found in 

https://mixmax.hepforge.org/ (mixmax_release_100_beta.zip)

The code has been compared with this reference implementation,
but as always the correctness of the code can not be guaranteed. 
Use with caution.

** USAGE **

1) To initialize MIXMAX one needs to call 
   mxmx_init(int32) with the matrix size as input parameters.
   Valid matrix sizes are: 
   3150 (default) 1260 1000 720 508 256 88 64 44 40 30 16 10
   88 or anything bigger should do any job (they all passed the
   BigCrush). The speed is independent of this number.
LL mxmx_init(Nmx)             

2) Seed the RNG. There are four available methods:
   o mxmx_seed_skip(ids_int32(4)): Seed with an array of up 
     to 4 integers (e.g. (/ clusterID, machineID, runID, MPIprocID/) ). 
     as an array. Mathematically guaranteed that if at least a 
     single bit of any of the 4 numbers is different, then 
     the different streams will not collide. This is the 
     perfect seeding method, but needs access to the 
     precomputed coefficients (look at the file mxmx_magic.dat
     and the routine Read_skiparray_from_file() at the end
     of the file test_mxmx.f90)

   o mxmx_seed_spbox(int64): As good as "traditional" seeding. 
     Very unlikely that different seeds collide.

   o mxmx_seed_lcg(int64): Another traditional seeding, but 
     different seeds can collide. Use reative prime seeds
     to avoid this (I could be understanding something wrong 
     here!).

   o mxmx_seed_vielbein(int32): Seed with unit vector. Mainly 
     for test. 

3) Get numbers with calls to mxmx. It will fill with RN
   either scalars or vectors of any intrinsic type 


"THE BEER-WARE LICENSE":
Alberto Ramos wrote this file. As long as you retain this 
notice you can do whatever you want with this stuff. If we meet some 
day, and you think this stuff is worth it, you can buy me a beer in 
return. <alberto.ramos@desy.de>

 

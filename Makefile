F90=gfortran48 
OPS=-std=f2003 -Wall -pedantic -O2
MPIF90=mpif90

VPATH=src
SRCDIR=$(VPATH)

test_mxmx.x: mixmax.o test_mxmx.f90
	$(F90) $(OPS) $^ -o $@

all: test_mxmx.x test_omp.x test_mpi.x

mixmax.o: mixmax.f90
	$(F90) $(OPS) -c $^ -o $@

test_omp.x: mixmax.f90 test_omp.f90
	$(F90) $(OPS) -fopenmp src/mixmax.f90 src/test_omp.f90 -o $@

test_mpi.x: mixmax.f90 test_mpi.f90
	$(MPIF90) $(OPS) -fopenmp src/mixmax.f90 src/test_mpi.f90 -o $@

clean:
	rm mixmax.mod mixmax.o test*.x *~ src/*~

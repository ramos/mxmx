F90=gfortran48 -std=f2008 -Wall -pedantic -march=native -funroll-loops -O2 -finline-limit=600 -fwhole-program -flto

VPATH=src
SRCDIR=$(VPATH)

all: test_mxmx.x

mixmax.o: mixmax.f90
	$(F90) -c $^ -o $@

test_mxmx.x: mixmax.o test_mxmx.f90
	$(F90) $^ -o $@

clean:
	rm mixmax.mod mixmax.o test_mxmx.x *~ src/*~

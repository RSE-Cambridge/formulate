# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O
FORMULATE_SRC = $(realpath ../../src)

simple: simple.F90 formulate.o
	$(FC) $(FFLAGS) -I $(FORMULATE_SRC) simple.F90 formulate.o -o simple

simple.F90: simple.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ simple.fypp simple.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -f simple *.mod *.o simple.F90 formulate.F90

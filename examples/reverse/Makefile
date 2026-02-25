# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O
FORMULATE_SRC = $(realpath ../../src)

reverse: reverse.F90 formulate.o
	$(FC) $(FFLAGS) reverse.F90 formulate.o -o reverse

reverse.F90: reverse.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ reverse.fypp reverse.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -f reverse *.mod *.o formulate.F90 reverse.F90

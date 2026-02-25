# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O
FORMULATE_SRC = $(realpath ../../src)

derived_type: derived_type.F90 formulate.o
	$(FC) $(FFLAGS) derived_type.F90 formulate.o -o derived_type

derived_type.F90: derived_type.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ derived_type.fypp derived_type.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -f derived_type *.mod *.o formulate.F90 derived_type.F90

# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O
FORMULATE_SRC = $(realpath ../src)

tests: tests.F90 formulate.o
	$(FC) $(FFLAGS) tests.F90 formulate.o -o tests

tests.F90: tests.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ tests.fypp tests.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -f tests *.mod *.o formulate.F90 tests.F90

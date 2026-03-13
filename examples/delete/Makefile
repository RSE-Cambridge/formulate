# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O
FORMULATE_SRC = $(realpath ../../src)

delete: delete.F90 formulate.o
	$(FC) $(FFLAGS) delete.F90 formulate.o -o delete

delete.F90: delete.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ delete.fypp delete.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -f delete *.mod *.o formulate.F90 delete.F90

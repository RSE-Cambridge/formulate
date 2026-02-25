# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O -ffree-line-length-none
FORMULATE_SRC = $(realpath ../../src)

rle_props: rle_lib.F90 rle_props.F90 formulate.o
	$(FC) $(FFLAGS) -I $(FORMULATE_SRC) $^ -o $@

rle_props.F90: rle_props.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ rle_props.fypp rle_props.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c -I $(FORMULATE_SRC) formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -f rle_props *.mod *.o formulate.F90 rle_props.F90

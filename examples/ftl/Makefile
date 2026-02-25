# SPDX-License-Identifier: MIT

FC = gfortran
FFLAGS = -O
FORMULATE_SRC = $(realpath ../../src)

.PHONY: top
top: ftl_string_test ftl_hashmap_test

ftl_string_test: ftl/src/ftlKinds.F90 \
                 ftl/src/ftlHash.F90 \
                 ftl/src/ftlString.F90 \
                 ftl_string_test.F90 formulate.o
	$(FC) $(FFLAGS) -I $(FORMULATE_SRC) $^ -o $@

ftl_hashmap_test: ftl/src/ftlKinds.F90 \
                  ftl/src/ftlHash.F90 \
                  ftl/src/ftlString.F90 \
                  ftl/instantiations/ftlHashMapStringInt.F90 \
                  ftl_hashmap_test.F90 formulate.o
	$(FC) $(FFLAGS) -I $(FORMULATE_SRC) -I ftl/src/ $^ -o $@

ftl/%:
	@if [ ! -d "ftl/" ]; then git clone https://github.com/SCM-NV/ftl/; fi

ftl_string_test.F90: ftl_string_test.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ ftl_string_test.fypp ftl_string_test.F90

ftl_hashmap_test.F90: ftl_hashmap_test.fypp $(FORMULATE_SRC)/*
	fypp -n -I $(FORMULATE_SRC)/ ftl_hashmap_test.fypp ftl_hashmap_test.F90

formulate.o: formulate.F90
	$(FC) $(FFLAGS) -c formulate.F90 -o formulate.o

formulate.F90: $(FORMULATE_SRC)/*
	fypp -n $(FORMULATE_SRC)/formulate.fypp formulate.F90

.PHONY: clean
clean:
	rm -rf ftl
	rm -f ftl_string_test ftl_hashmap_test *.mod *.o \
        ftl_string_test.F90 ftl_hashmap_test.F90 formulate.F90

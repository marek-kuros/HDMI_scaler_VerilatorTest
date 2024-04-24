######################################################################
# Description: Makefile for verilating DSP module of scaler for HDMI
# File based on Makefile provided in example for Veriltaor SW
######################################################################
# Check for sanity to avoid later confusion

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).

# ifeq ($(VERILATOR_ROOT),)
# VERILATOR = verilator
# VERILATOR_COVERAGE = verilator_coverage
# else
# export VERILATOR_ROOT
# VERILATOR = $(VERILATOR_ROOT)/bin/verilator
# VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
# endif

#other Variables

#EnV 
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage

#setting flags - you can read more -> https://verilator.org/guide/latest/exe_verilator.html?highlight=flags#cmdoption-CFLAGS
VERILATOR_FLAGS += -cc --exe
VERILATOR_FLAGS += --x-assign unique #for testing if reset works
#VERILATOR_FLAGS += -Wall

#VERILATOR_FLAGS += --trace

VERILATOR_FLAGS += --assert
VERILATOR_FLAGS += --coverage

VERILATOR_INPUT = -f FilesList.txt sim_top.cpp

### top name #########################################################
TOP_MODULE = dc_toplevel
### timescale ########################################################
######################################################################
default: run

run:
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)
	$(MAKE) -j -C obj_dir -f Vtop.mk
	@echo "---- VERILATOR_COVERAGE --------------------------"
	$(VERILATOR_COVERAGE) --annotate logs/annotated logs/coverage.dat
	@echo "---- RUN TEST ------------------------------------"
	obj_dir/Vdc_toplevel
	@echo "---- DONE ----------------------------------------"

build_binary:
	verilator --binary -j 0 -f FilesList.txt --top-module $(TOP_MODULE) -Wno-fatal
build_cc:
	verilator --cc -j 0 -f FilesList.txt --top-module $(TOP_MODULE) -Wno-fatal
#testing
SIM_FILES = sim_top.cpp VGA_PLL.cpp
build_test:
	verilator --cc --exe --build -j 2 $(SIM_FILES) -f FilesList.txt --top-module $(TOP_MODULE) -Wno-fatal
clean:
	-rm -rf obj_dir *.log *.dmp *.vpd core

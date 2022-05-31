

# Definitions
# {{{
PCF_FLAGS ?= --pcf-allow-unconstrained
PCF_FLAGS ?=
PROJECT_NAME = wavelet_transform
ARTIFACTS = intermediates
SOURCES = src/*.*v
SRC_DIR = src
STATS_DIR = util_stats
ICEBREAKER_DEV = up5k
ICEBREAKER_PCF = pinconfig/icebreaker.pcf
LOGS=logs
OUT=build
OUT_SIM=sim_build

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONPATH := test:$(PYTHONPATH)
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

ICEBREAKER_PKG = sg48
SEED = 1
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e "s/^.*=\s*//"')
VINC := $(VERILATOR_ROOT)/include

# }}}
#
all: $(OUT)/$(PROJECT_NAME).bin

# {{{
$(ARTIFACTS)/yosys.json: $(SOURCES)
	yosys -l $(LOGS)/yosys.log -p 'synth_ice40 -top $(PROJECT_NAME) -json $(ARTIFACTS)/yosys.json' $(SOURCES)
# }}}

$(ARTIFACTS)/nextpnr.asc: $(ARTIFACTS)/yosys.json $(ICEBREAKER_PCF)
	nextpnr-ice40 -l $(LOGS)/nextpnr.log --seed $(SEED) --freq 20 --package $(ICEBREAKER_PKG) --$(ICEBREAKER_DEV) --asc $@ --pcf $(ICEBREAKER_PCF) $(PCF_FLAGS) --json $<

$(OUT)/$(PROJECT_NAME).bin: $(ARTIFACTS)/nextpnr.asc
	icepack $< $@

prog: $(OUT)/$(PROJECT_NAME).bin
	iceprog $<

obj_dir/V$(PROJECT_NAME).cpp: ./src/$(PROJECT_NAME).v
	verilator --trace -Wall -cc $< -I$(SRC_DIR) -MMD

obj_dir/V$(PROJECT_NAME)__ALL.a: obj_dir/V$(PROJECT_NAME).cpp
	make -C obj_dir -f V$(PROJECT_NAME).mk

$(OUT_SIM)/$(PROJECT_NAME): sim/$(PROJECT_NAME).cpp obj_dir/V$(PROJECT_NAME)__ALL.a
	g++ -I$(VINC) -I obj_dir \
		$(VINC)/verilated.cpp \
		$(VINC)/verilated_vcd_c.cpp \
		sim/$(PROJECT_NAME).cpp obj_dir/V$(PROJECT_NAME)__ALL.a \
		-o $(OUT_SIM)/$(PROJECT_NAME)

$(OUT_SIM)/$(PROJECT_NAME).vcd: $(OUT_SIM)/$(PROJECT_NAME)
	./$(OUT_SIM)/$(PROJECT_NAME)
	mv $(PROJECT_NAME).vcd $(OUT_SIM)/$(PROJECT_NAME).vcd

vcd: $(OUT_SIM)/$(PROJECT_NAME).vcd

show_synth: src/wavelet_transform.v
	yosys -p "read_verilog $^; proc; opt; show -colors 2 -width -signed"

show_util: $(OUT)/$(PROJECT_NAME).bin
	cat ./logs/nextpnr.log | sed -n '/Device utilisation/,/^$$/p'

view_trace: vcd
	gtkwave $(OUT_SIM)/$(PROJECT_NAME).vcd

buildsim: $(OUT_SIM)/$(PROJECT_NAME).vcd

resources:
	yosys -p "synth_ice40 -wavelet_transform $(PROJECT_NAME)" $(SOURCES) | awk '/=== wavelet_transform ===/,/CHECK/'
	# yosys -p "synth_ice40 -wavelet_transform $(PROJECT_NAME)" $(SOURCES) > $(STATS_DIR)/$$(date +%F_%T)


# TODO: remove everything except for .gitignore
test_cwt:
	rm -rf ./sim_build/*
	iverilog -DCOCOTB_SIM -o sim_build/sim.vvp  -s wavelet_transform -g2012 src/wavelet_transform.v  src/fir.v src/shift_register_line.v
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_cwt vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp


# TODO: remove everything except for .gitignore
clean:
	rm -f $(ARTIFACTS)/*.json
	rm -f $(ARTIFACTS)/*.asc
	rm -f $(OUT)/*
	rm -f $(OUT_SIM)/*
	rm -f $(LOGS)/*
	rm -f obj_dir/*
	rm -f $(PROJECT_NAME)


.PHONY: all clean prog buildsim vcd resources

# if error will delete target
.DELETE_ON_ERROR:

DEPS := $(wildcard obj_dir/*.d)

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif

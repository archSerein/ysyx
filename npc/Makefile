TOPNAME = top
VCD = ./V$(TOPNAME).vcd
NXDC_FILES = constr/top.nxdc
INC_PATH ?= $(NPC_HOME)/include
ALL ?=
IMG ?= /home/serein/ysyx/ysyx-workbench/am-kernels/tests/am-tests/build/$(ALL)-riscv32e-npc.bin
ELF ?= /home/serein/ysyx/ysyx-workbench/am-kernels/tests/am-tests/build/$(ALL)-riscv32e-npc.elf

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD -Wall --trace --Wno-DECLFILENAME \
				-O3 --x-assign unique --x-initial fast --noassert --build -cc

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

-include $(NPC_HOME)/include/config/auto.conf
-include $(NPC_HOME)/include/config/auto.conf.cmd

.PHONY: waves
waves: $(VCD)
	@echo
	@echo "### WAVES ###"
	gtkwave $(VCD)

$(VCD): $(BUILD_DIR)/$(TOPNAME)
	@echo
	@echo "### SIMULATING ###"
	@./$(BUILD_DIR)/$(TOPNAME) $(IMG) +verilator+rand+reset+2

# constraint file
# SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# $(SRC_AUTO_BIND): $(NXDC_FILES)
#	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
# include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CXXFLAGS += $(shell llvm-config --cxxflags)
LDFLAGS += -lreadline $(shell llvm-config --libs)

-include $(NPC_HOME)/.config
ifeq ($(CONFIG_DIFFTEST), y)
	LDFLAGS += -L/home/serein/ysyx/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so
endif

$(BIN): $(VSRCS) $(CSRCS) # $(NVBOARD_ARCHIVE)
		@python3 $(NPC_HOME)/trans.py
		@rm -rf $(OBJ_DIR)
		$(VERILATOR) $(VERILATOR_CFLAGS) \
		+incdir+/home/serein/ysyx/ysyx-workbench/npc/vsrc \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

run: $(BIN)
	$(call git_commit, "sim RTL")  # DO NOT REMOVE THIS LINE!!!
	@$^ $(IMG)
	@echo "all done"

gdb: $(BIN)
	@$^ $(IMG) $(BIN_PATH)

all:
	@echo "Write this Makefile by your self."

clean:
	rm -rf $(BUILD_DIR) *.vcd

.PHONY: clean run all

include ../Makefile
include $(NPC_HOME)/scripts/config.mk

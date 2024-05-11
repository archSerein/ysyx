TOPNAME = top
VCD = ./V$(TOPNAME).vcd 
NXDC_FILES = constr/top.nxdc
INC_PATH ?=
ALL ?=
IMG = /home/serein/ysyx/ysyx-workbench/am-kernels/tests/am-tests/build/$(ALL)-riscv32e-npc.bin
ELF = /home/serein/ysyx/ysyx-workbench/am-kernels/tests/am-tests/build/$(ALL)-riscv32e-npc.elf

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD \
				-O3 --x-assign unique --x-initial fast --noassert --build -cc

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

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
CXXFLAGS += $(shell llvm-config --cxxflags) -DCONFIG_ITRACE -DCONFIG_WATCHPOINT -DCONFIG_FTRACE # -DCONFIG_DIFFTEST -DCONFIG_MTRACE
LDFLAGS += -lreadline $(shell llvm-config --libs) -L/home/serein/ysyx/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so


$(BIN): $(VSRCS) $(CSRCS) # $(NVBOARD_ARCHIVE)
		@rm -rf $(OBJ_DIR)
		$(VERILATOR) $(VERILATOR_CFLAGS) \
		+incdir+/home/serein/ysyx/ysyx-workbench/npc/vsrc \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

sim: $(BIN)
	$(call git_commit, "sim RTL")  # DO NOT REMOVE THIS LINE!!!
	@$^ $(IMG) $(ELF) -b
	@echo "all done"

gdb: $(BIN)
	@$^ $(BIN_PATH)

all:
	@echo "Write this Makefile by your self."

clean:
	rm -rf $(BUILD_DIR) *.vcd

.PHONY: clean sim all

include ../Makefile
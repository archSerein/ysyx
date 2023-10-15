all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!

	verilator -Wall --trace -cc ./vsrc/*.v --exe ./csrc/*.cpp
	make -C obj_dir -f Valu.mk Valu
	./obj_dir/Valu
	@echo "Write this Makefile by your self."

include ../Makefile

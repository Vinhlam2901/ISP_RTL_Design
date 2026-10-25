# Author: Hai Cao
# Copyright 2024

.PHONY: make sim
make sim:
	@xrun -access +rwc -f ./flist
.PHONY: wave
wave:
	@(simvision wave.vcd &)
.PHONY: gui
gui:
	@xrun -gui -access +rwc -f ./flist -input restore.tcl
.PHONY: clean
clean:
	@echo "-> CLEAN"
	@rm -rf x* *.vcd *.shm *.log
.PHONY: lint
lint:
	@xrun -hal -gui -f ./flist

.PHONY: create_filelist
create_filelist:
	@rm -f flist
	@echo "# =============== Included tesbench files ==============="
	@find ./../01_tb \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) -exec echo "Included file:" {} \;
	@echo "# =============== Included source code files ==============="
	@find ./../00_src -name "*param*.sv" -exec echo "Included PACKAGE file:" {} \;
	@find ./../00_src \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) ! -name "*param*.sv" -exec echo "Included SRC file:" {} \;
	
	@echo "-sv" >> flist
	@echo "-timescale 1ns/100ps" >> flist
	@echo "# TESTBENCH FILES" >> flist
	@find ./../01_tb \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) >> flist
	@echo "# SOURCE CODE FILES" >> flist
	@echo "# --- 1. Packages & Parameters ---" >> flist
	@find ./../00_src -name "*param*.sv" >> flist
	
	@echo "# --- 2. Design Modules ---" >> flist
	@find ./../00_src \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) ! -name "*param*.sv" >> flist
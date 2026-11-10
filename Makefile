IVERILOG  = iverilog
VVP       = vvp
VERILATOR = verilator
GOWIN_SH  = gw_sh
GOWIN_ENV = LD_PRELOAD="/usr/lib/libstdc++.so.6 /opt/gowin-eda-edu-ide/lib/libQt5XcbQpa.so.5"
BITSTREAM = fpga/impl/pnr/tang_top_cc14.fs

SRCS = top_module.v tb_student.v

.PHONY: all check check-k5 lint fpga prog flash clean

all: check

check: sim_top
	$(VVP) sim_top

sim_top: $(SRCS)
	$(IVERILOG) -g2012 -s tb_student -o sim_top $(SRCS)

check-k5: sim_k5
	$(VVP) sim_k5

sim_k5: $(SRCS)
	$(IVERILOG) -g2012 -s tb_student -Ptb_student.K_VAL=5 -o sim_k5 $(SRCS)

lint:
	$(VERILATOR) --lint-only -Wall top_module.v
	$(VERILATOR) --lint-only -Wall --top-module tang_top_cc14 top_module.v fpga/sync2ff.v fpga/tang_top_cc14.v

fpga:
	cd fpga && $(GOWIN_ENV) $(GOWIN_SH) run_gowin.tcl

prog:
	openFPGALoader -b tangprimer25k $(BITSTREAM)

flash:
	openFPGALoader -b tangprimer25k -f $(BITSTREAM)

clean:
	rm -f sim_top sim_k5 *.vvp *.vcd

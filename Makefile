IVERILOG  = iverilog
VVP       = vvp
VERILATOR = verilator

SRCS = top_module.v tb_student.v

.PHONY: all check check-k5 lint clean

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

clean:
	rm -f sim_top sim_k5 *.vvp *.vcd

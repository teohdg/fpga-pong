# ---------------------------------------------------------------------------
# GHDL build/sim for the Pong-style game logic and its testbenches.
# Requires: ghdl (mcode or llvm).   Run:  make sim
#
# The DUT uses the Synopsys std_logic_unsigned package, so GHDL needs
# -fsynopsys, and -fexplicit resolves the "=" operator overload it triggers.
# Everything is VHDL-93, so this also compiles under Vivado xsim unchanged.
# ---------------------------------------------------------------------------
GHDL   ?= ghdl
STD     = --std=93
FLAGS   = -fsynopsys -fexplicit
WORKDIR = work

SRC = src/game_state_machine.vhd \
	  src/counter.vhd \
	  src/input_buffer.vhd \
	  src/ssd_decoder.vhd

TB = tb/tb_game_state_machine.vhd \
	 tb/tb_input_buffer.vhd \
	 tb/tb_ssd_decoder.vhd \
	 tb/tb_game_integration.vhd

TOPS = tb_game_state_machine tb_input_buffer tb_ssd_decoder tb_game_integration

GHDLFLAGS = $(STD) $(FLAGS) --workdir=$(WORKDIR) -P$(WORKDIR)

.PHONY: all sim analyze clean $(TOPS)

all: sim

$(WORKDIR):
	mkdir -p $(WORKDIR)

analyze: | $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $(SRC) $(TB)

# Elaborate + run a single testbench, e.g.:  make tb_ssd_decoder
$(TOPS): analyze
	$(GHDL) -e $(GHDLFLAGS) $@
	$(GHDL) -r $(GHDLFLAGS) $@ --stop-time=2ms --assert-level=error

sim: analyze
	@for t in $(TOPS); do \
		echo "=== $$t ==="; \
		$(GHDL) -e $(GHDLFLAGS) $$t; \
		$(GHDL) -r $(GHDLFLAGS) $$t --stop-time=2ms --assert-level=error; \
	done

clean:
	rm -rf $(WORKDIR) *.cf work-obj*.cf e~*.o *.o $(TOPS)

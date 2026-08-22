# ---------------------------------------------------------------------------
# GHDL build/sim for the Pong-style game logic and its testbenches.
# Requires: ghdl (mcode or llvm).
#
#   make sim       run the four unit/integration testbenches
#   make sim-top   run the full top-level structural testbench
#   make all       both of the above
#
# The DUT uses the Synopsys std_logic_unsigned package, so GHDL needs
# -fsynopsys, and -fexplicit resolves the "=" operator overload it triggers.
# Everything is VHDL-93, so this also compiles under Vivado xsim unchanged.
# ---------------------------------------------------------------------------
GHDL   ?= ghdl
STD     = --std=93
FLAGS   = -fsynopsys -fexplicit
WORKDIR = work

# --- game-logic core (used by every flow) ---------------------------------
CORE = src/game_state_machine.vhd \
	   src/counter.vhd \
	   src/input_buffer.vhd \
	   src/ssd_decoder.vhd

# --- unit + integration testbenches ---------------------------------------
TB = tb/tb_game_state_machine.vhd \
	 tb/tb_input_buffer.vhd \
	 tb/tb_ssd_decoder.vhd \
	 tb/tb_game_integration.vhd

TOPS = tb_game_state_machine tb_input_buffer tb_ssd_decoder tb_game_integration

# --- extra leaf cells the structural top needs ----------------------------
# Note: lab6_clock_divider / lab7_clk60hz are deliberately NOT compiled for the
# top-level sim -- tb/sim_dividers.vhd supplies fast stand-ins of the same
# entities so a full game finishes in a few hundred edges. For a hardware build
# you compile src/lab6_clock_divider.vhd and src/lab7_clk60hz.vhd instead.
TOPSRC = src/led_array.vhd \
		 src/lab7_mux.vhd \
		 src/main_structural.vhd

GHDLFLAGS = $(STD) $(FLAGS) --workdir=$(WORKDIR) -P$(WORKDIR)

.PHONY: all sim sim-top analyze clean $(TOPS)

all: sim sim-top

$(WORKDIR):
	mkdir -p $(WORKDIR)

analyze: | $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $(CORE) $(TB)

# Elaborate + run a single unit testbench, e.g.:  make tb_ssd_decoder
$(TOPS): analyze
	$(GHDL) -e $(GHDLFLAGS) $@
	$(GHDL) -r $(GHDLFLAGS) $@ --stop-time=2ms --assert-level=error

sim: analyze
	@for t in $(TOPS); do \
		echo "=== $$t ==="; \
		$(GHDL) -e $(GHDLFLAGS) $$t; \
		$(GHDL) -r $(GHDLFLAGS) $$t --stop-time=2ms --assert-level=error; \
	done

# Full structural top. Compiles the core, the extra leaf cells, the FAST
# sim-only dividers, main_structural, and the top-level TB, then runs to a win.
sim-top: | $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $(CORE) src/led_array.vhd src/lab7_mux.vhd tb/sim_dividers.vhd src/main_structural.vhd tb/tb_main_structural.vhd
	$(GHDL) -e $(GHDLFLAGS) tb_main_structural
	@echo "=== tb_main_structural ==="
	$(GHDL) -r $(GHDLFLAGS) tb_main_structural --stop-time=2ms --assert-level=error

clean:
	rm -rf $(WORKDIR) *.cf work-obj*.cf e~*.o *.o $(TOPS) tb_main_structural

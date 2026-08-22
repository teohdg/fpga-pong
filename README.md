# Pong-style game logic — self-checking testbenches

Five VHDL-93 testbenches, each self-checking (they assert expected behaviour and
print a single `PASS`/`FAIL` line). They run in **Vivado xsim** and in **GHDL**
(license-free `make sim` / `make sim-top`).

| Testbench | DUT | What it proves |
|-----------|-----|----------------|
| `tb_game_state_machine.vhd` | `game_state_machine` | Full rally FSM: serve, climb (`leds` 000→110→111), both S2 branches (return vs miss), descend, both S4 branches, and **async reset** mid-operation. Checks the exact `(state, leds)` pair after every clock. |
| `tb_input_buffer.vhd` | `input_buffer` | Press latching between game-clock ticks, sticky hold, **clear on `game_clk` rising edge** (edge-triggered, not level), p1-over-p2 priority on simultaneous press, and that `reset_in` is a pure passthrough that does **not** clear the latches. |
| `tb_ssd_decoder.vhd` | `ssd_decoder` | Exhaustive: all 16 codes on `digit1` (`toggle=0`) and all 16 on `digit2` (`toggle=1`) against a golden segment table, plus the `cat` select bit. 32 checks. |
| `tb_game_integration.vhd` | `game_state_machine` + `counter` | End-to-end scoring datapath: player1 wins (`winner=01`), player2 wins (`winner=10`, asserts the ball reached the left edge), endless rally scores nobody (`winner=00`). |
| `tb_main_structural.vhd` | `main_structural` (whole design) | The real structural top through its pins (`clk_in, reset, sw, player1, player2` → `led, seg, cat`): reset serve position, `led` one-hot invariant, `seg` always a legal digit/blank, ball animation, a full play-to-win detected from the display flash, and `cat` toggling. |

## Running with GHDL

```sh
make sim        # the four unit / integration testbenches
make sim-top    # the full top-level structural testbench
make all        # everything
make tb_ssd_decoder   # or run one unit TB by name
make clean
```

GHDL needs two flags, already baked into the Makefile:

- `-fsynopsys` — the design uses the Synopsys `std_logic_unsigned` package.
- `-fexplicit` — resolves the `"="` operator overload that `std_logic_unsigned`
  introduces on top of `std_logic_1164`. Vivado xsim resolves this silently.
  Neither flag changes design behaviour; they are elaboration flags only.

## Running in Vivado xsim

Add the sources and the testbench you want, set it as the simulation top, and
run. No special flags. For the unit TBs, add `src/*.vhd` (the core four) plus the
TB. For the top-level TB, see the note below about the clock dividers.

## The top-level testbench and the clock dividers

`main_structural` builds its game clock with `lab6_clock_divider` (÷50M or ÷25M)
and a refresh tick with `lab7_clk60hz` (÷200k). With those real ratios a single
game to a 10-point win is on the order of a **billion** `clk_in` edges — no
simulator will sit through it.

So `tb/sim_dividers.vhd` provides **fast sim-only architectures of the same two
entities** (`clk_in/2`), and `make sim-top` compiles those in place of the real
divider files. `main_structural` is **not modified** and never sees them in
synthesis — for hardware you compile `src/lab6_clock_divider.vhd` and
`src/lab7_clk60hz.vhd` as normal. To reproduce in xsim, add `src/` (minus the two
real dividers) plus `tb/sim_dividers.vhd` and `tb/tb_main_structural.vhd`.

The top-level TB checks everything at the observable boundary only. It never
reaches inside the DUT: it detects the win from the display itself (a win forces
the winning digit to blank while `game_clk='0'`, and pre-win the score digits are
never blank), so a blank `seg` while `cat='0'` can only mean `winner="01"`.

## Files

```
src/    game_state_machine.vhd  counter.vhd  input_buffer.vhd  ssd_decoder.vhd
        led_array.vhd  lab7_mux.vhd  main_structural.vhd
        lab6_clock_divider.vhd  lab7_clk60hz.vhd      (real dividers, for hardware)
tb/     tb_game_state_machine.vhd  tb_input_buffer.vhd  tb_ssd_decoder.vhd
        tb_game_integration.vhd  tb_main_structural.vhd
        sim_dividers.vhd                                (fast dividers, sim only)
Makefile
```

The `src/` copies here were transcribed from the reviewed source so the repo runs
out of the box; use your canonical files if they differ.

# Pong-style game logic self-checking testbenches

Four VHDL-93 testbenches, each self-checking (they assert expected behaviour and
print a single `PASS`/`FAIL` line). They run in **Vivado xsim** and in **GHDL**
(license-free `make sim`).

| Testbench | DUT | What it proves |
|-----------|-----|----------------|
| `tb_game_state_machine.vhd` | `game_state_machine` | Full rally FSM: serve, climb (`leds` 000→110→111), both S2 branches (return vs miss), descend, both S4 branches (return vs miss), and **async reset** mid-operation. Checks the exact `(state, leds)` pair after every clock. |
| `tb_input_buffer.vhd` | `input_buffer` | Press latching between game-clock ticks, sticky hold, **clear on `game_clk` rising edge** (edge-triggered, not level), p1-over-p2 priority on simultaneous press, and that `reset_in` is a pure passthrough that does **not** clear the latches. |
| `tb_ssd_decoder.vhd` | `ssd_decoder` | Exhaustive: all 16 codes on `digit1` (`toggle=0`) and all 16 on `digit2` (`toggle=1`) against a golden segment table, plus the `cat` select bit. 32 checks total. |
| `tb_game_integration.vhd` | `game_state_machine` + `counter` | End-to-end scoring: player1 wins when player2 keeps missing (`winner=01`), player2 wins the mirror case (`winner=10`, and asserts the ball actually reached the left edge), and an endless rally scores nobody (`winner=00`). |

## Running with GHDL

```sh
make sim        # analyze + elaborate + run all four, fail on any assertion
make tb_ssd_decoder   # or run one by name
make clean
```

GHDL needs two flags, already baked into the Makefile:

- `-fsynopsys` the design uses the Synopsys `std_logic_unsigned` package.
- `-fexplicit` resolves the `"="` operator overload that `std_logic_unsigned`
  introduces on top of `std_logic_1164`. Vivado xsim resolves this silently;
  GHDL needs to be told. This is a simulator-elaboration flag only — it does
  **not** change design behaviour.

## Running in Vivado xsim

Add `src/*.vhd` and `tb/*.vhd` to the simulation set, set the top to the
testbench you want (e.g. `tb_game_state_machine`), and run. No special flags are
needed — xsim handles `std_logic_unsigned` natively. Each TB stops itself
(it gates its own clock), so the run ends on its own and prints the PASS line to
the console.

## Note on the integration testbench

`main_structural` also instantiates `lab6_clock_divider`, `lab7_clk60hz`,
`led_array` and `lab7_mux`, which are not in this source set, so a testbench
bound directly to `main_structural` cannot elaborate. `game_state_machine` and
`counter` *are* the whole game-logic core and are wired here exactly as
`main_structural` wires them (shared game clock and reset, FSM `state` → counter
`state`), so the integration TB exercises the real scoring datapath. If you drop
the four missing helper modules into `src/`, a top-level `main_structural`
testbench is a small addition — say the word.

## Files

```
src/    game_state_machine.vhd  counter.vhd  input_buffer.vhd  ssd_decoder.vhd
tb/     tb_game_state_machine.vhd  tb_input_buffer.vhd
        tb_ssd_decoder.vhd  tb_game_integration.vhd
Makefile
```

The `src/` copies here were transcribed from the reviewed source so the repo runs
out of the box; use your canonical files if they differ.

----------------------------------------------------------------------------------
-- Self-checking testbench for input_buffer
--
-- input_buffer latches a button press (p1/p2) any time between game-clock ticks
-- and clears both latches on each rising edge of game_clk_in (sampled on clk).
-- Behaviour verified here:
--   * latches power up at 0
--   * a p1 press sets p1Buf and holds it (sticky) until a game_clk edge
--   * a p2 press sets p2Buf and holds it
--   * a rising edge on game_clk_in clears BOTH latches
--   * holding game_clk_in high does NOT keep clearing (edge-triggered)
--   * a falling edge on game_clk_in does nothing
--   * simultaneous p1+p2 -> p1 wins (p2Buf stays low that cycle)
--   * resetBuf_out is a pure passthrough of reset_in and does NOT clear latches
--
-- Dialect: VHDL-93. Runs in Vivado xsim and GHDL.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_input_buffer is
end tb_input_buffer;

architecture sim of tb_input_buffer is
    signal clk          : std_logic := '0';
    signal reset_in     : std_logic := '0';
    signal p1           : std_logic := '0';
    signal p2           : std_logic := '0';
    signal game_clk_in  : std_logic := '0';
    signal p1Buf        : std_logic;
    signal p2Buf        : std_logic;
    signal resetBuf_out : std_logic;

    signal done : std_logic := '0';

    function sl(b : std_logic) return string is
    begin
        if b = '1' then return "1"; else return "0"; end if;
    end function;
begin
    dut : entity work.input_buffer
        port map (
            clk => clk, reset_in => reset_in,
            p1 => p1, p2 => p2, game_clk_in => game_clk_in,
            p1Buf => p1Buf, p2Buf => p2Buf, resetBuf_out => resetBuf_out
        );

    clk_gen : process
    begin
        while done = '0' loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    stim : process
        variable errors : integer := 0;

        -- Apply p1/p2/game_clk for one clk edge, then check the latches.
        procedure step_ib(constant p1v, p2v, gckv : in std_logic;
                          constant ep1, ep2 : in std_logic) is
        begin
            p1          <= p1v;
            p2          <= p2v;
            game_clk_in <= gckv;
            wait until rising_edge(clk);
            wait for 1 ns;
            if (p1Buf /= ep1) or (p2Buf /= ep2) then
                report "IB MISMATCH: expected p1Buf=" & sl(ep1) &
                       " p2Buf=" & sl(ep2) &
                       " ; got p1Buf=" & sl(p1Buf) &
                       " p2Buf=" & sl(p2Buf)
                    severity error;
                errors := errors + 1;
            end if;
        end procedure;

        procedure check_reset(constant exp : in std_logic;
                             constant msg : in string) is
        begin
            if resetBuf_out /= exp then
                report msg & " : expected resetBuf_out=" & sl(exp) &
                       " ; got " & sl(resetBuf_out)
                    severity error;
                errors := errors + 1;
            end if;
        end procedure;
    begin
        -- resetBuf_out passthrough starts low
        wait for 1 ns;
        check_reset('0', "reset passthrough at start");

        -- settle: latches power up at 0
        step_ib('0','0','0', '0','0');
        step_ib('0','0','0', '0','0');

        -- p1 press latches and is sticky
        step_ib('1','0','0', '1','0');
        step_ib('0','0','0', '1','0');

        -- p2 press latches; p1 latch untouched
        step_ib('0','1','0', '1','1');
        step_ib('0','0','0', '1','1');

        -- rising edge on game_clk clears BOTH latches
        step_ib('0','0','1', '0','0');
        -- game_clk held high: no re-clear, so p1 press latches normally
        step_ib('1','0','1', '1','0');
        -- falling edge on game_clk does nothing (p1 latch holds)
        step_ib('0','0','0', '1','0');
        -- rising edge again clears
        step_ib('0','0','1', '0','0');

        -- priority: simultaneous p1+p2 (game_clk held high) -> p1 wins
        step_ib('1','1','1', '1','0');
        -- release p1, keep p2 -> p2 now latches
        step_ib('0','1','1', '1','1');
        step_ib('0','0','1', '1','1');

        --------------------------------------------------------------------
        -- reset_in is passthrough only: it must NOT clear the latches.
        -- Latches are currently 1/1; game_clk held high so no edge clears.
        --------------------------------------------------------------------
        reset_in <= '1';
        wait for 1 ns;
        check_reset('1', "reset passthrough asserted");
        step_ib('0','0','1', '1','1');   -- latches survive reset_in=1
        step_ib('0','0','1', '1','1');
        check_reset('1', "reset still high while latches held");
        reset_in <= '0';
        wait for 1 ns;
        check_reset('0', "reset passthrough deasserted");

        if errors = 0 then
            report "tb_input_buffer: PASS (all checks matched)" severity note;
        else
            report "tb_input_buffer: FAIL with " & integer'image(errors) &
                   " mismatch(es)" severity error;
        end if;

        done <= '1';
        wait;
    end process;
end sim;

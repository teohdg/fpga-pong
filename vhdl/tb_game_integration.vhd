----------------------------------------------------------------------------------
-- Integration testbench: game_state_machine  +  counter
--
-- This reproduces the scoring datapath of main_structural exactly:
--   * FSM and counter share the game clock and reset
--   * FSM.state drives counter.state
-- (main_structural itself also instantiates lab6_clock_divider, lab7_clk60hz,
--  led_array and lab7_mux, which are not part of the reviewed source set, so
--  binding a TB directly to main_structural cannot elaborate. These two units
--  are the whole game-logic core, so they are exercised together here.)
--
-- Player buttons are driven off the FSM state so rallies play automatically:
--   * a player "returns" the ball by pressing on its edge state
--   * a player "misses" by not pressing, which sends the ball to S0 and scores
--     the opponent.
--
-- Scenarios (each preceded by a reset):
--   A. player2 never returns -> player1 scores every rally -> winner = "01"
--   B. player2 returns, player1 never returns -> player2 wins -> winner = "10"
--      (also asserts the ball actually reached the left edge S4)
--   C. both players always return -> endless rally, nobody scores, winner "00"
--
-- Dialect: VHDL-93. Runs in Vivado xsim and GHDL.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_game_integration is
end tb_game_integration;

architecture sim of tb_game_integration is
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal player1    : std_logic;
    signal player2    : std_logic;
    signal state      : std_logic_vector(3 downto 0);
    signal leds       : std_logic_vector(2 downto 0);
    signal p1_score   : std_logic_vector(3 downto 0);
    signal p2_score   : std_logic_vector(3 downto 0);
    signal winner     : std_logic_vector(1 downto 0);

    -- rally control
    signal mode_p2_ret : std_logic := '0';   -- player2 returns at right edge (S2)
    signal mode_p1_ret : std_logic := '0';   -- player1 returns at left edge (S4)

    signal done : std_logic := '0';
begin
    ----------------------------------------------------------------------
    -- Button drivers: press on the relevant edge state when that player is
    -- set to "return". Combinational off state, sampled by the FSM next edge.
    ----------------------------------------------------------------------
    player2 <= '1' when (mode_p2_ret = '1' and state = "0010") else '0';
    player1 <= '1' when (mode_p1_ret = '1' and state = "0100") else '0';

    fsm : entity work.game_state_machine
        port map (clk => clk, reset => reset,
                  player1 => player1, player2 => player2,
                  state => state, leds => leds);

    cnt : entity work.counter
        port map (clk => clk, reset => reset, state => state,
                  output1 => p1_score, output2 => p2_score, winner => winner);

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
        variable cyc    : integer;
        variable saw_s4 : boolean;

        procedure do_reset is
        begin
            reset <= '1';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            reset <= '0';
            wait for 1 ns;
        end procedure;

        -- Run the game clock until someone wins or the cap is hit.
        -- Records whether the left edge (S4) was ever visited.
        procedure play_until_win(constant cap : in integer) is
        begin
            cyc := 0;
            saw_s4 := false;
            while (winner = "00") and (cyc < cap) loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if state = "0100" then saw_s4 := true; end if;
                cyc := cyc + 1;
            end loop;
        end procedure;

        procedure fail(constant msg : in string) is
        begin
            report msg severity error;
            errors := errors + 1;
        end procedure;
    begin
        --------------------------------------------------------------------
        -- Scenario A: player1 wins because player2 never returns
        --------------------------------------------------------------------
        mode_p2_ret <= '0';
        mode_p1_ret <= '0';
        do_reset;
        if winner /= "00" then fail("A: winner not cleared by reset"); end if;
        play_until_win(2000);
        if winner /= "01" then
            fail("A: expected player1 win (winner=01), got other value");
        end if;
        if p2_score /= "0000" then
            fail("A: player2 scored during a player1-only run");
        end if;
        report "Scenario A finished after " & integer'image(cyc) &
               " game cycles, winner=01" severity note;

        --------------------------------------------------------------------
        -- Scenario B: player2 wins; ball must reach the left edge each rally
        --------------------------------------------------------------------
        mode_p2_ret <= '1';
        mode_p1_ret <= '0';
        do_reset;
        play_until_win(4000);
        if winner /= "10" then
            fail("B: expected player2 win (winner=10), got other value");
        end if;
        if not saw_s4 then
            fail("B: ball never reached left edge S4 (return path broken)");
        end if;
        if p1_score /= "0000" then
            fail("B: player1 scored during a player2-only run");
        end if;
        report "Scenario B finished after " & integer'image(cyc) &
               " game cycles, winner=10" severity note;

        --------------------------------------------------------------------
        -- Scenario C: endless rally -> no score, no winner
        --------------------------------------------------------------------
        mode_p2_ret <= '1';
        mode_p1_ret <= '1';
        do_reset;
        saw_s4 := false;
        for k in 0 to 399 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            if state = "0100" then saw_s4 := true; end if;
            if winner /= "00" then
                fail("C: unexpected winner during an endless rally");
                exit;
            end if;
            if (p1_score /= "0000") or (p2_score /= "0000") then
                fail("C: unexpected score during an endless rally");
                exit;
            end if;
        end loop;
        if not saw_s4 then
            fail("C: ball never bounced to the left edge in the rally");
        end if;
        report "Scenario C: 400 cycles of rally with no score" severity note;

        --------------------------------------------------------------------
        if errors = 0 then
            report "tb_game_integration: PASS (all scenarios matched)" severity note;
        else
            report "tb_game_integration: FAIL with " & integer'image(errors) &
                   " error(s)" severity error;
        end if;

        done <= '1';
        wait;
    end process;
end sim;

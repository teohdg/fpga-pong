----------------------------------------------------------------------------------
-- Self-checking testbench for game_state_machine
--
-- Verifies the full ball-rally state machine:
--   S0 (0000) serve        -> S1
--   S1 (0001) climb right   leds 000..110, then -> S2 with leds 111
--   S2 (0010) right edge    player2=1 -> S3 (return) ; player2=0 -> S0 (miss)
--   S3 (0011) descend left   leds 110..001, then -> S4 with leds 000
--   S4 (0100) left edge     player1=1 -> S1 (return) ; player1=0 -> S0 (miss)
--
-- Covers: both S2 branches, both S4 branches, the climb/descend counters,
-- and asynchronous reset (mid-operation).
--
-- Dialect: VHDL-93. Runs in Vivado xsim and GHDL. No VHDL-2008 constructs.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_game_state_machine is
end tb_game_state_machine;

architecture sim of tb_game_state_machine is
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal player1 : std_logic := '0';
    signal player2 : std_logic := '0';
    signal state   : std_logic_vector(3 downto 0);
    signal leds    : std_logic_vector(2 downto 0);

    signal done : std_logic := '0';

    function img(v : std_logic_vector) return string is
    begin
        return integer'image(to_integer(unsigned(v)));
    end function;
begin
    dut : entity work.game_state_machine
        port map (
            clk => clk, reset => reset,
            player1 => player1, player2 => player2,
            state => state, leds => leds
        );

    -- Free-running clock that halts cleanly at end of test
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

        -- Drive p1/p2 for one cycle, clock, then check the resulting outputs.
        procedure step(constant p1v, p2v : in std_logic;
                       constant es : in std_logic_vector(3 downto 0);
                       constant el : in std_logic_vector(2 downto 0)) is
        begin
            player1 <= p1v;
            player2 <= p2v;
            wait until rising_edge(clk);
            wait for 1 ns;  -- let combinational outputs settle
            if (state /= es) or (leds /= el) then
                report "STEP MISMATCH: expected state=" & img(es) &
                       " leds=" & img(el) &
                       " ; got state=" & img(state) &
                       " leds=" & img(leds)
                    severity error;
                errors := errors + 1;
            end if;
        end procedure;

        procedure check_now(constant es : in std_logic_vector(3 downto 0);
                            constant el : in std_logic_vector(2 downto 0);
                            constant msg : in string) is
        begin
            if (state /= es) or (leds /= el) then
                report msg & " : expected state=" & img(es) & " leds=" & img(el) &
                       " ; got state=" & img(state) & " leds=" & img(leds)
                    severity error;
                errors := errors + 1;
            end if;
        end procedure;
    begin
        --------------------------------------------------------------------
        -- Async reset: outputs must be forced without any clock edge
        --------------------------------------------------------------------
        reset   <= '1';
        player1 <= '0';
        player2 <= '0';
        wait for 12 ns;
        check_now("0000", "000", "ASYNC RESET (initial)");
        reset <= '0';
        wait for 1 ns;

        --------------------------------------------------------------------
        -- Rally 1: climb, player2 RETURNS, descend, player1 RETURNS
        --------------------------------------------------------------------
        step('0','0', "0001","000");  -- S0 -> S1 (serve)
        step('0','0', "0001","001");
        step('0','0', "0001","010");
        step('0','0', "0001","011");
        step('0','0', "0001","100");
        step('0','0', "0001","101");
        step('0','0', "0001","110");
        step('0','0', "0010","111");  -- S1(leds=110) -> S2 right edge
        step('0','1', "0011","110");  -- S2 + player2 -> S3 return
        step('0','0', "0011","101");
        step('0','0', "0011","100");
        step('0','0', "0011","011");
        step('0','0', "0011","010");
        step('0','0', "0011","001");
        step('0','0', "0100","000");  -- S3(leds=001) -> S4 left edge
        step('1','0', "0001","001");  -- S4 + player1 -> S1 return

        --------------------------------------------------------------------
        -- Rally 2: climb again, player2 MISSES at right edge -> S0
        --------------------------------------------------------------------
        step('0','0', "0001","010");
        step('0','0', "0001","011");
        step('0','0', "0001","100");
        step('0','0', "0001","101");
        step('0','0', "0001","110");
        step('0','0', "0010","111");  -- reach S2
        step('0','0', "0000","000");  -- S2 + no player2 -> S0 (miss)

        --------------------------------------------------------------------
        -- Rally 3: re-serve, player2 returns, then player1 MISSES at S4 -> S0
        --------------------------------------------------------------------
        step('0','0', "0001","000");  -- S0 -> S1
        step('0','0', "0001","001");
        step('0','0', "0001","010");
        step('0','0', "0001","011");
        step('0','0', "0001","100");
        step('0','0', "0001","101");
        step('0','0', "0001","110");
        step('0','0', "0010","111");  -- S2
        step('0','1', "0011","110");  -- return
        step('0','0', "0011","101");
        step('0','0', "0011","100");
        step('0','0', "0011","011");
        step('0','0', "0011","010");
        step('0','0', "0011","001");
        step('0','0', "0100","000");  -- S4
        step('0','0', "0000","000");  -- S4 + no player1 -> S0 (miss)

        --------------------------------------------------------------------
        -- Async reset mid-flight: climb a bit, yank reset, expect idle
        --------------------------------------------------------------------
        step('0','0', "0001","000");
        step('0','0', "0001","001");
        step('0','0', "0001","010");
        reset <= '1';
        wait for 2 ns;                -- no clock edge here
        check_now("0000", "000", "ASYNC RESET (mid-operation)");
        reset <= '0';
        wait for 1 ns;
        step('0','0', "0001","000");  -- resumes serving from idle

        --------------------------------------------------------------------
        -- Summary
        --------------------------------------------------------------------
        if errors = 0 then
            report "tb_game_state_machine: PASS (all checks matched)" severity note;
        else
            report "tb_game_state_machine: FAIL with " & integer'image(errors) &
                   " mismatch(es)" severity error;
        end if;

        done <= '1';
        wait;
    end process;
end sim;

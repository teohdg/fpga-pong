----------------------------------------------------------------------------------
-- Top-level structural testbench: main_structural
--
-- Exercises the REAL structural netlist end to end through its actual pins
-- (clk_in, reset, sw, player1, player2 -> led, seg, cat). The only substitution
-- is the two clock dividers, which are replaced by fast sim-only architectures of
-- the same entities (see sim_dividers.vhd) so a full game finishes in a few
-- hundred clk_in edges. main_structural itself is unmodified.
--
-- Everything below is checked at the observable boundary only -- the TB never
-- reaches inside the DUT:
--
--   * Reset          : led shows the serve position (one-hot 00000001),
--                       seg/cat carry no metavalues.
--   * led invariant  : led is one-hot on every cycle after reset
--                       (proves game_clk -> FSM.leds -> led_array).
--   * seg invariant  : seg is always a legal digit pattern or blank, never X/U
--                       (proves the score -> digit-gate -> ssd_decoder path only
--                        ever presents valid digits).
--   * Liveness       : the ball visits several distinct led positions
--                       (proves the game clock is actually advancing the FSM).
--   * Play to a win  : with both buttons idle, player2 keeps missing, so player1
--                       reaches the win. The win is detected purely from the
--                       display: a win forces the left digit to blank while
--                       game_clk='0', so a blank seg while cat='0' can only mean
--                       winner="01". Pre-win the left digit is always a real score
--                       (0..9, never blank), so this is unambiguous.
--   * Display mux    : clocked long enough to see cat toggle, proving the
--                       ssd_decoder refresh mux and both cathode phases are live.
--
-- Dialect: VHDL-93. Runs in Vivado xsim and GHDL.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_main_structural is
end tb_main_structural;

architecture sim of tb_main_structural is
    signal clk_in  : std_logic := '0';
    signal reset   : std_logic := '1';
    signal player1 : std_logic := '0';
    signal player2 : std_logic := '0';
    signal sw      : std_logic := '0';
    signal led     : std_logic_vector(7 downto 0);
    signal seg     : std_logic_vector(6 downto 0);
    signal cat     : std_logic;

    signal done : std_logic := '0';

    constant BLANK : std_logic_vector(6 downto 0) := "0000000";

    -- Golden segment patterns for scores 0..9 (same nonstandard bus order as the
    -- decoder spec). Any seg value outside {these, BLANK} is illegal.
    type seg_rom_t is array (0 to 9) of std_logic_vector(6 downto 0);
    constant SEG_ROM : seg_rom_t := (
        0 => "0111111", 1 => "0110000", 2 => "1011011", 3 => "1111001",
        4 => "1110100", 5 => "1101101", 6 => "1101111", 7 => "0111000",
        8 => "1111111", 9 => "1111101" );

    -- true if v is a clean std_logic_vector of only '0'/'1'
    function is_01(v : std_logic_vector) return boolean is
    begin
        for i in v'range loop
            if v(i) /= '0' and v(i) /= '1' then
                return false;
            end if;
        end loop;
        return true;
    end function;

    function is_onehot(v : std_logic_vector) return boolean is
        variable n : integer := 0;
    begin
        if not is_01(v) then return false; end if;
        for i in v'range loop
            if v(i) = '1' then n := n + 1; end if;
        end loop;
        return n = 1;
    end function;

    function is_legal_seg(v : std_logic_vector(6 downto 0)) return boolean is
    begin
        if not is_01(v) then return false; end if;
        if v = BLANK then return true; end if;
        for d in 0 to 9 loop
            if v = SEG_ROM(d) then return true; end if;
        end loop;
        return false;
    end function;
begin
    ------------------------------------------------------------------------
    -- Device under test: the real structural top. The two clock dividers
    -- bind to the fast sim architectures compiled by `make sim-top`.
    ------------------------------------------------------------------------
    dut : entity work.main_structural
        port map (
            clk_in  => clk_in,
            reset   => reset,
            player1 => player1,
            player2 => player2,
            sw      => sw,
            led     => led,
            seg     => seg,
            cat     => cat );

    clk_gen : process
    begin
        while done = '0' loop
            clk_in <= '0'; wait for 5 ns;
            clk_in <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    stim : process
        variable errors     : integer := 0;
        variable distinct   : integer := 0;
        variable seen       : std_logic_vector(7 downto 0) := (others => '0');
        variable won        : boolean := false;
        variable win_edge   : integer := -1;
        variable cat_flipped : boolean := false;
        variable e          : integer;

        procedure chk(constant cond : in boolean; constant msg : in string) is
        begin
            if not cond then
                report msg severity error;
                errors := errors + 1;
            end if;
        end procedure;

        -- one clk_in period, sampling shortly after the rising edge
        procedure step is
        begin
            wait until rising_edge(clk_in);
            wait for 1 ns;
        end procedure;
    begin
        ------------------------------------------------------------------
        -- Reset, then release
        ------------------------------------------------------------------
        reset <= '1';
        for i in 0 to 3 loop step; end loop;
        chk(led = "00000001", "reset: led not at serve position (00000001)");
        chk(is_01(seg),       "reset: seg has metavalues");
        chk(cat = '0' or cat = '1', "reset: cat is a metavalue");

        reset <= '0';
        step;

        ------------------------------------------------------------------
        -- Play with both buttons idle. player2 never returns, so player1
        -- climbs to the win. Along the way, enforce the boundary invariants
        -- and record ball animation + the win-flash.
        ------------------------------------------------------------------
        e := 0;
        while (e < 20000) and (not won) loop
            step;
            e := e + 1;

            -- led one-hot at all times
            if not is_onehot(led) then
                chk(false, "led not one-hot during play");
                exit;
            end if;

            -- record distinct ball positions for the liveness check
            if is_01(led) then
                for b in 0 to 7 loop
                    if led(b) = '1' and seen(b) = '0' then
                        seen(b) := '1';
                        distinct := distinct + 1;
                    end if;
                end loop;
            end if;

            -- seg must always be a legal digit or blank
            if not is_legal_seg(seg) then
                chk(false, "seg illegal (not a digit pattern or blank)");
                exit;
            end if;

            -- win-flash detector: left digit blanked while its cathode is active
            if (cat = '0') and (seg = BLANK) then
                won := true;
                win_edge := e;
            end if;
        end loop;

        chk(won, "no win-flash observed -- player1 never reached the win");
        chk(distinct >= 3,
            "ball did not animate through enough positions (game clock stalled?)");
        if won then
            report "Win-flash (winner=01) first seen at clk_in edge " &
                   integer'image(win_edge) severity note;
        end if;
        report "Distinct led positions visited before win: " &
               integer'image(distinct) severity note;

        ------------------------------------------------------------------
        -- Display mux liveness: clock on until the ssd_decoder refresh
        -- toggle flips cat to '1', proving the mux and both cathode phases
        -- are alive. Keep enforcing the seg legality invariant meanwhile.
        ------------------------------------------------------------------
        e := 0;
        while (e < 80000) and (not cat_flipped) loop
            step;
            e := e + 1;
            if not is_legal_seg(seg) then
                chk(false, "seg illegal during display-mux phase");
                exit;
            end if;
            if cat = '1' then
                cat_flipped := true;
            end if;
        end loop;
        chk(cat_flipped, "cat never toggled -- ssd_decoder refresh mux appears dead");

        ------------------------------------------------------------------
        if errors = 0 then
            report "tb_main_structural: PASS (all boundary checks matched)"
                severity note;
        else
            report "tb_main_structural: FAIL with " & integer'image(errors) &
                   " error(s)" severity error;
        end if;

        done <= '1';
        wait;
    end process;
end sim;

----------------------------------------------------------------------------------
-- Self-checking testbench for ssd_decoder
--
-- The decoder time-multiplexes two BCD-ish nibbles onto one 7-seg bus:
--   curr = digit1 when toggle='0' else digit2 ; cat <= toggle
--   toggle = counter(16), i.e. it flips every 2^16 clocks.
--
-- Strategy:
--   Phase 1 (toggle=0, the reset state): drive every code 0x0..0xF on digit1
--            with digit2 forced to the complement, and check seg against a
--            golden table + cat='0'. This is exhaustive over the decode ROM.
--   Phase 2: clock until cat toggles to '1', then sweep every code on digit2
--            (digit1 complemented) and check seg + cat='1'. Proves the mux
--            select and the cat output, not just the ROM.
--
-- Golden segment patterns are taken as the design's specification (this bus
-- ordering is non-standard, so the table below *is* the spec being locked in).
-- Codes 0xA..0xF are blank ("0000000").
--
-- Dialect: VHDL-93. Runs in Vivado xsim and GHDL.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ssd_decoder is
end tb_ssd_decoder;

architecture sim of tb_ssd_decoder is
    signal clk    : std_logic := '0';
    signal digit1 : std_logic_vector(3 downto 0) := (others => '0');
    signal digit2 : std_logic_vector(3 downto 0) := (others => '0');
    signal seg    : std_logic_vector(6 downto 0);
    signal cat    : std_logic;

    signal done : std_logic := '0';

    function nib(i : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(i, 4));
    end function;

    function img(v : std_logic_vector) return string is
        variable s : string(1 to v'length);
        variable k : integer := 1;
    begin
        for b in v'range loop
            if v(b) = '1' then s(k) := '1'; else s(k) := '0'; end if;
            k := k + 1;
        end loop;
        return s;
    end function;

    -- Golden 7-seg patterns (the design's specification).
    function expected_seg(d : integer) return std_logic_vector is
    begin
        case d is
            when 0 => return "0111111";
            when 1 => return "0110000";
            when 2 => return "1011011";
            when 3 => return "1111001";
            when 4 => return "1110100";
            when 5 => return "1101101";
            when 6 => return "1101111";
            when 7 => return "0111000";
            when 8 => return "1111111";
            when 9 => return "1111101";
            when others => return "0000000";   -- A..F blank
        end case;
    end function;
begin
    dut : entity work.ssd_decoder
        port map (clk => clk, digit1 => digit1, digit2 => digit2,
                  seg => seg, cat => cat);

    -- Fast clock so Phase 2 (2^16 ticks to flip toggle) runs quickly.
    clk_gen : process
    begin
        while done = '0' loop
            clk <= '0'; wait for 2 ns;
            clk <= '1'; wait for 2 ns;
        end loop;
        wait;
    end process;

    stim : process
        variable errors : integer := 0;
        variable guard  : integer;

        procedure check_seg(constant code : in integer;
                            constant ecat : in std_logic;
                            constant src  : in string) is
            variable eseg : std_logic_vector(6 downto 0);
        begin
            eseg := expected_seg(code);
            if (seg /= eseg) or (cat /= ecat) then
                report "SSD MISMATCH (" & src & " code=" & integer'image(code) &
                       "): expected seg=" & img(eseg) &
                       " cat=" & img("" & ecat) &
                       " ; got seg=" & img(seg) &
                       " cat=" & img("" & cat)
                    severity error;
                errors := errors + 1;
            end if;
        end procedure;
    begin
        --------------------------------------------------------------------
        -- Phase 1: toggle=0 -> curr follows digit1. Exhaustive 0x0..0xF.
        --------------------------------------------------------------------
        for i in 0 to 15 loop
            digit1 <= nib(i);
            digit2 <= not nib(i);       -- force a different value on the idle input
            wait for 1 ns;              -- combinational settle
            check_seg(i, '0', "digit1");
        end loop;

        --------------------------------------------------------------------
        -- Advance the clock until toggle (== cat) flips to 1.
        --------------------------------------------------------------------
        guard := 0;
        while cat /= '1' and guard < 70000 loop
            wait until rising_edge(clk);
            wait for 0 ns;
            guard := guard + 1;
        end loop;
        assert cat = '1'
            report "SSD: cat never toggled to 1 within guard limit" severity error;

        --------------------------------------------------------------------
        -- Phase 2: toggle=1 -> curr follows digit2. Exhaustive 0x0..0xF.
        --------------------------------------------------------------------
        for i in 0 to 15 loop
            digit2 <= nib(i);
            digit1 <= not nib(i);
            wait for 1 ns;
            check_seg(i, '1', "digit2");
        end loop;

        if errors = 0 then
            report "tb_ssd_decoder: PASS (all 32 decode checks matched)" severity note;
        else
            report "tb_ssd_decoder: FAIL with " & integer'image(errors) &
                   " mismatch(es)" severity error;
        end if;

        done <= '1';
        wait;
    end process;
end sim;

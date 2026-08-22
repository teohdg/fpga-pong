----------------------------------------------------------------------------------
-- SIMULATION-ONLY clock dividers.
--
-- These are drop-in fast replacements for lab6_clock_divider and lab7_clk60hz,
-- with identical entity names and port maps but tiny divide ratios so a full
-- game plays out in a few hundred clk_in edges instead of billions.
--
-- They are compiled ONLY into the top-level testbench flow (`make sim-top`) in
-- place of the real divider files. main_structural is NOT modified and never
-- sees these in synthesis. The real lab6_clock_divider.vhd / lab7_clk60hz.vhd
-- are what you build for hardware.
--
-- game_clk = clk_in / 2  (divider toggles every clk_in rising edge)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab6_clock_divider is
    Port ( clk_in : in  STD_LOGIC;
           reset  : in  STD_LOGIC;
           sel    : in  STD_LOGIC;
           clkout : out STD_LOGIC );
end lab6_clock_divider;

architecture sim of lab6_clock_divider is
    signal r : std_logic := '0';
begin
    -- sel is ignored in simulation; both speeds map to clk_in/2 so games are short.
    process(clk_in, reset)
    begin
        if reset = '1' then
            r <= '0';
        elsif rising_edge(clk_in) then
            r <= not r;
        end if;
    end process;
    clkout <= r;
end sim;

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab7_clk60hz is
    Port ( clk    : in  STD_LOGIC;
           reset  : in  STD_LOGIC;
           clkout : out STD_LOGIC );
end lab7_clk60hz;

architecture sim of lab7_clk60hz is
    signal r : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            r <= '0';
        elsif rising_edge(clk) then
            r <= not r;
        end if;
    end process;
    clkout <= r;
end sim;

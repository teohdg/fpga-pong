----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/20/2026 04:27:07 PM
-- Design Name: 
-- Module Name: lab7_mux - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lab7_mux is
    Port (
        sel : in  STD_LOGIC;
        I0  : in  STD_LOGIC_VECTOR(3 downto 0);
        I1  : in  STD_LOGIC_VECTOR(3 downto 0);
        Y   : out STD_LOGIC_VECTOR(3 downto 0)
    );
end lab7_mux;

architecture Behavioral of lab7_mux is
begin

    process(sel, I0, I1)
    begin
        if sel = '0' then
            Y <= I0;
        else
            Y <= I1;
        end if;
    end process;

end Behavioral;


--------------------------------------------------------------------------------
-- clk_reset_gen.vhd
--
-- Clock and reset generation for the Cortex-M0 DesignStart SoC on the Atlys
-- board. The Atlys has a 100 MHz oscillator; this project divides it down to a
-- 50 MHz system clock by default (CLK_DIV = 2). A simple synchronous reset
-- stretcher holds HRESETn low for several cycles after the external reset.
--
-- NOTE: For a production design on Spartan-6 you would normally use a DCM/PLL
-- primitive rather than a toggle-flop divider. A behavioural divider is used
-- here to keep the RTL vendor-neutral and simulatable with open tools; see
-- docs/architecture.md ("Clocking") for how to swap in a DCM_SP.
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_reset_gen is
    generic (
        CLK_DIV     : integer := 2;    -- 100 MHz / 2 = 50 MHz
        RESET_CYCLES : integer := 16
    );
    port (
        clk_in   : in  std_logic;      -- 100 MHz board oscillator
        rst_in   : in  std_logic;      -- external reset, active high
        clk_sys  : out std_logic;      -- divided system clock
        hresetn  : out std_logic       -- synchronous active-low reset
    );
end entity clk_reset_gen;

architecture rtl of clk_reset_gen is
    signal div_cnt   : integer range 0 to CLK_DIV-1 := 0;
    signal clk_div_r : std_logic := '0';
    signal rst_cnt   : integer range 0 to RESET_CYCLES := 0;
    signal resetn_r  : std_logic := '0';
begin

    -- Clock divider. For CLK_DIV = 2 this is a simple toggle.
    clkdiv : process (clk_in)
    begin
        if rising_edge(clk_in) then
            if CLK_DIV <= 2 then
                clk_div_r <= not clk_div_r;
            else
                if div_cnt = (CLK_DIV/2 - 1) then
                    clk_div_r <= not clk_div_r;
                    div_cnt   <= 0;
                else
                    div_cnt <= div_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    clk_sys <= clk_div_r;

    -- Reset stretcher on the system clock domain.
    rstgen : process (clk_div_r)
    begin
        if rising_edge(clk_div_r) then
            if rst_in = '1' then
                rst_cnt  <= 0;
                resetn_r <= '0';
            elsif rst_cnt = RESET_CYCLES then
                resetn_r <= '1';
            else
                rst_cnt  <= rst_cnt + 1;
                resetn_r <= '0';
            end if;
        end if;
    end process;

    hresetn <= resetn_r;

end architecture rtl;

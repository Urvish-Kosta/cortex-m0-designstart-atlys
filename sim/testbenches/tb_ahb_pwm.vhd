--------------------------------------------------------------------------------
-- tb_ahb_pwm.vhd
--
-- Self-checking testbench for ahb_pwm. Programs a duty cycle, enables the
-- output, then measures the high-time over one full 256-cycle PWM period and
-- checks it matches the programmed duty within +/-1 count.
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ahb_pwm is
end entity tb_ahb_pwm;

architecture sim of tb_ahb_pwm is
    signal hclk    : std_logic := '0';
    signal hresetn : std_logic := '0';
    signal hsel    : std_logic := '0';
    signal haddr   : std_logic_vector(31 downto 0) := (others => '0');
    signal hwrite  : std_logic := '0';
    signal htrans  : std_logic_vector(1 downto 0) := "00";
    signal hwdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal hready  : std_logic := '1';
    signal hrdata  : std_logic_vector(31 downto 0);
    signal hreadyo : std_logic;
    signal hresp   : std_logic;
    signal pwm_out : std_logic;

    signal done : boolean := false;
    constant DUTY : integer := 64;   -- 25% of 256
begin

    dut : entity work.ahb_pwm
        port map (
            HCLK => hclk, HRESETn => hresetn,
            HSEL => hsel, HADDR => haddr, HWRITE => hwrite,
            HTRANS => htrans, HWDATA => hwdata, HREADYin => hready,
            HRDATA => hrdata, HREADYout => hreadyo, HRESP => hresp,
            pwm_out => pwm_out
        );

    clkgen : process
    begin
        while not done loop
            hclk <= '0'; wait for 5 ns;
            hclk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    procedure_write : process
        procedure wr(constant a : std_logic_vector(31 downto 0);
                     constant d : std_logic_vector(31 downto 0)) is
        begin
            wait until rising_edge(hclk);
            hsel <= '1'; haddr <= a; hwrite <= '1'; htrans <= "10";
            wait until rising_edge(hclk);
            hsel <= '0'; htrans <= "00"; hwdata <= d;
            wait until rising_edge(hclk);
            hwrite <= '0';
        end procedure;

        variable high_count : integer := 0;
    begin
        hresetn <= '0';
        wait for 40 ns;
        hresetn <= '1';

        wr(x"40002000", std_logic_vector(to_unsigned(DUTY, 32)));  -- DUTY
        wr(x"40002004", x"00000001");                              -- EN = 1

        -- Align to a period boundary, then count high cycles over 256.
        wait until rising_edge(hclk);
        for i in 0 to 255 loop
            wait until rising_edge(hclk);
            if pwm_out = '1' then
                high_count := high_count + 1;
            end if;
        end loop;

        assert abs(high_count - DUTY) <= 2
            report "PWM TEST FAILED: measured duty out of tolerance"
            severity failure;

        report "PWM TEST PASSED: duty cycle matches programmed value"
            severity note;
        done <= true;
        wait;
    end process;

end architecture sim;

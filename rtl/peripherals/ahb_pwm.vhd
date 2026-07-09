--------------------------------------------------------------------------------
-- ahb_pwm.vhd
--
-- AHB-Lite 8-bit PWM peripheral for the Cortex-M0 DesignStart SoC.
--
-- A free-running 8-bit counter compares against the DUTY register to generate a
-- PWM waveform, used in the demonstrator to vary LED brightness. The BTN0 task
-- in the firmware reads the DUTY value back and prints it over UART.
--
-- Register map (offsets from the peripheral base):
--   0x00 DUTY : R/W [7:0] duty cycle (0 = off, 255 = full on)
--   0x04 EN   : R/W [0]   output enable
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ahb_pwm is
    port (
        HCLK      : in  std_logic;
        HRESETn   : in  std_logic;
        -- AHB-Lite slave interface
        HSEL      : in  std_logic;
        HADDR     : in  std_logic_vector(31 downto 0);
        HWRITE    : in  std_logic;
        HTRANS    : in  std_logic_vector(1 downto 0);
        HWDATA    : in  std_logic_vector(31 downto 0);
        HREADYin  : in  std_logic;
        HRDATA    : out std_logic_vector(31 downto 0);
        HREADYout : out std_logic;
        HRESP     : out std_logic;
        -- PWM output
        pwm_out   : out std_logic
    );
end entity ahb_pwm;

architecture rtl of ahb_pwm is

    signal addr_q  : std_logic_vector(3 downto 0);
    signal write_q : std_logic;
    signal valid_q : std_logic;

    signal duty   : unsigned(7 downto 0) := (others => '0');
    signal enable : std_logic := '0';
    signal cnt    : unsigned(7 downto 0) := (others => '0');

begin

    ahb_addr_phase : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                valid_q <= '0';
                write_q <= '0';
                addr_q  <= (others => '0');
            elsif HREADYin = '1' then
                if HSEL = '1' and HTRANS(1) = '1' then
                    valid_q <= '1';
                    write_q <= HWRITE;
                    addr_q  <= HADDR(3 downto 0);
                else
                    valid_q <= '0';
                    write_q <= '0';
                end if;
            end if;
        end if;
    end process;

    ahb_write : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                duty   <= (others => '0');
                enable <= '0';
            elsif valid_q = '1' and write_q = '1' then
                case addr_q is
                    when x"0" => duty   <= unsigned(HWDATA(7 downto 0));
                    when x"4" => enable <= HWDATA(0);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    ahb_read : process (addr_q, duty, enable)
    begin
        HRDATA <= (others => '0');
        case addr_q is
            when x"0" => HRDATA(7 downto 0) <= std_logic_vector(duty);
            when x"4" => HRDATA(0) <= enable;
            when others => HRDATA <= (others => '0');
        end case;
    end process;

    HREADYout <= '1';
    HRESP     <= '0';

    --------------------------------------------------------------------------
    -- PWM generation: output high while counter < duty.
    --------------------------------------------------------------------------
    pwm_gen : process (HCLK)
    begin
        if rising_edge(HCLK) then
            if HRESETn = '0' then
                cnt     <= (others => '0');
                pwm_out <= '0';
            else
                cnt <= cnt + 1;
                if enable = '1' and cnt < duty then
                    pwm_out <= '1';
                else
                    pwm_out <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture rtl;

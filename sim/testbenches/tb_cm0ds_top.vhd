--------------------------------------------------------------------------------
-- tb_cm0ds_top.vhd
--
-- Smoke-test bench for the SoC top level using the simulation stub CPU. It
-- clocks the design, releases reset, drives the switches, and watches the LED
-- outputs change as the stub CPU writes 0xAA to the GPIO LED register. It also
-- captures the UART TX line.
--
-- This proves the AHB fabric, decoder, memory and peripherals elaborate and
-- respond. It does NOT verify Cortex-M0 instruction execution (that requires
-- the real Arm core + firmware).
--
-- NOTE ON BINDING: cm0ds_top declares CORTEXM0DS as a *component*. To run this
-- bench against the simulation stub, your simulator must bind that component to
-- work.CORTEXM0DS(stub). In Xilinx ISim / ModelSim this happens automatically
-- by name; in GHDL, analyse cortexm0ds_stub.vhd and elaborate with
-- `--syn-binding` (or provide a configuration). The per-peripheral benches
-- (tb_ahb_uart/gpio/pwm) need no such binding and are the ones run by
-- sim/scripts/run_tests.sh; this top-level bench is provided for full-SoC
-- bring-up once the real Arm core is in place.
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cm0ds_top is
end entity tb_cm0ds_top;

architecture sim of tb_cm0ds_top is
    signal clk_100m : std_logic := '0';
    signal rst_btn  : std_logic := '1';
    signal uart_rx  : std_logic := '1';
    signal uart_tx  : std_logic;
    signal led      : std_logic_vector(7 downto 0);
    signal sw       : std_logic_vector(7 downto 0) := x"5A";
    signal btn      : std_logic_vector(4 downto 0) := (others => '0');
    signal pwm_led  : std_logic;

    signal done : boolean := false;
begin

    dut : entity work.cm0ds_top
        generic map (CLK_HZ => 50_000_000, BAUD_RATE => 9600)
        port map (
            clk_100m => clk_100m,
            rst_btn  => rst_btn,
            uart_rx  => uart_rx,
            uart_tx  => uart_tx,
            led      => led,
            sw       => sw,
            btn      => btn,
            pwm_led  => pwm_led
        );

    -- 100 MHz clock
    clk_gen : process
    begin
        while not done loop
            clk_100m <= '0'; wait for 5 ns;
            clk_100m <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    stim : process
    begin
        rst_btn <= '1';
        wait for 200 ns;
        rst_btn <= '0';

        -- Let the stub CPU run its little access script.
        wait for 2 us;

        assert led = x"AA"
            report "SoC smoke test FAILED: LED register did not read back 0xAA."
            severity failure;

        report "SoC smoke test PASSED: LED = 0xAA written via AHB GPIO."
            severity note;

        done <= true;
        wait;
    end process;

end architecture sim;


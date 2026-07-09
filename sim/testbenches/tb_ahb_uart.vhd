--------------------------------------------------------------------------------
-- tb_ahb_uart.vhd
--
-- Self-checking testbench for ahb_uart. Writes a byte to the DATA register and
-- decodes the resulting serial waveform on tx at the configured baud rate,
-- checking start bit, 8 data bits (LSB first) and stop bit. Uses a deliberately
-- small CLK_HZ/BAUD ratio so the test runs quickly.
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ahb_uart is
end entity tb_ahb_uart;

architecture sim of tb_ahb_uart is
    -- 1 MHz clock, 100 kBaud -> divisor 10 (fast to simulate)
    constant CLK_HZ    : integer := 1_000_000;
    constant BAUD      : integer := 100_000;
    constant DIVISOR   : integer := CLK_HZ / BAUD;     -- 10
    constant CLK_PER   : time := 1 us;                 -- 1 MHz
    constant BIT_TIME  : time := CLK_PER * DIVISOR;     -- one serial bit

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
    signal rx      : std_logic := '1';
    signal tx      : std_logic;

    signal done : boolean := false;

    constant TEST_BYTE : std_logic_vector(7 downto 0) := x"4B";  -- 'K'
begin

    dut : entity work.ahb_uart
        generic map (CLK_HZ => CLK_HZ, BAUD_RATE => BAUD)
        port map (
            HCLK => hclk, HRESETn => hresetn,
            HSEL => hsel, HADDR => haddr, HWRITE => hwrite,
            HTRANS => htrans, HWDATA => hwdata, HREADYin => hready,
            HRDATA => hrdata, HREADYout => hreadyo, HRESP => hresp,
            rx => rx, tx => tx
        );

    clkgen : process
    begin
        while not done loop
            hclk <= '0'; wait for CLK_PER/2;
            hclk <= '1'; wait for CLK_PER/2;
        end loop;
        wait;
    end process;

    stim : process
        variable rx_byte : std_logic_vector(7 downto 0);
    begin
        hresetn <= '0';
        wait for 3 us;
        hresetn <= '1';
        wait until rising_edge(hclk);

        -- Write TEST_BYTE to DATA (offset 0x00), address then data phase.
        wait until rising_edge(hclk);
        hsel <= '1'; haddr <= x"40000000"; hwrite <= '1'; htrans <= "10";
        wait until rising_edge(hclk);
        hsel <= '0'; htrans <= "00"; hwdata <= x"000000" & TEST_BYTE;
        wait until rising_edge(hclk);
        hwrite <= '0';

        -- Wait for the start bit (tx goes low), then sample at each bit centre.
        wait until tx = '0';
        wait for BIT_TIME/2;               -- centre of start bit
        assert tx = '0' report "UART TEST FAILED: bad start bit" severity failure;

        for i in 0 to 7 loop
            wait for BIT_TIME;             -- advance to centre of data bit i
            rx_byte(i) := tx;              -- LSB first
        end loop;

        wait for BIT_TIME;                 -- advance to centre of stop bit
        assert tx = '1' report "UART TEST FAILED: bad stop bit" severity failure;

        assert rx_byte = TEST_BYTE
            report "UART TEST FAILED: transmitted byte mismatch" severity failure;

        report "UART TEST PASSED: byte 0x4B transmitted correctly" severity note;
        done <= true;
        wait;
    end process;

end architecture sim;

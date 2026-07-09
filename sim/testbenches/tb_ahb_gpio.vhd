--------------------------------------------------------------------------------
-- tb_ahb_gpio.vhd
--
-- Self-checking testbench for ahb_gpio. Emulates AHB-Lite master transactions
-- (address phase then data phase) to:
--   * write the LED register and check the led output pins,
--   * drive the switch inputs and read them back through SWITCH,
--   * drive a button, wait past debounce, and read it back through BUTTON.
--
-- Author: Urvish Kosta
-- License: MIT (see LICENSE at repository root)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ahb_gpio is
end entity tb_ahb_gpio;

architecture sim of tb_ahb_gpio is
    constant DB : integer := 8;   -- tiny debounce for fast simulation

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

    signal led : std_logic_vector(7 downto 0);
    signal sw  : std_logic_vector(7 downto 0) := (others => '0');
    signal btn : std_logic_vector(4 downto 0) := (others => '0');

    signal done : boolean := false;

    -- AHB write: address phase then data phase.
    procedure ahb_write(
        constant addr : in std_logic_vector(31 downto 0);
        constant data : in std_logic_vector(31 downto 0);
        signal clk    : in  std_logic;
        signal a_sel  : out std_logic;
        signal a_addr : out std_logic_vector(31 downto 0);
        signal a_wr   : out std_logic;
        signal a_tr   : out std_logic_vector(1 downto 0);
        signal a_wd   : out std_logic_vector(31 downto 0)) is
    begin
        -- address phase
        wait until rising_edge(clk);
        a_sel <= '1'; a_addr <= addr; a_wr <= '1'; a_tr <= "10";
        -- data phase
        wait until rising_edge(clk);
        a_sel <= '0'; a_tr <= "00"; a_wd <= data;
        wait until rising_edge(clk);
        a_wr <= '0';
    end procedure;

    procedure ahb_read_setup(
        constant addr : in std_logic_vector(31 downto 0);
        signal clk    : in  std_logic;
        signal a_sel  : out std_logic;
        signal a_addr : out std_logic_vector(31 downto 0);
        signal a_wr   : out std_logic;
        signal a_tr   : out std_logic_vector(1 downto 0)) is
    begin
        wait until rising_edge(clk);
        a_sel <= '1'; a_addr <= addr; a_wr <= '0'; a_tr <= "10";
        wait until rising_edge(clk);   -- addr_q captures here
        a_sel <= '0'; a_tr <= "00";
        wait until rising_edge(clk);   -- data phase: hrdata now reflects addr_q
    end procedure;

begin

    dut : entity work.ahb_gpio
        generic map (DEBOUNCE_CYCLES => DB)
        port map (
            HCLK => hclk, HRESETn => hresetn,
            HSEL => hsel, HADDR => haddr, HWRITE => hwrite,
            HTRANS => htrans, HWDATA => hwdata, HREADYin => hready,
            HRDATA => hrdata, HREADYout => hreadyo, HRESP => hresp,
            led => led, sw => sw, btn => btn
        );

    clkgen : process
    begin
        while not done loop
            hclk <= '0'; wait for 5 ns;
            hclk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    stim : process
    begin
        hresetn <= '0';
        wait for 40 ns;
        hresetn <= '1';
        wait until rising_edge(hclk);

        -- Write LED = 0xA5
        ahb_write(x"40001000", x"000000A5", hclk, hsel, haddr, hwrite, htrans, hwdata);
        wait until rising_edge(hclk);
        assert led = x"A5"
            report "GPIO TEST FAILED: LED output mismatch" severity failure;
        report "GPIO: LED write OK" severity note;

        -- Drive switches, read SWITCH
        sw <= x"3C";
        wait for 50 ns;
        ahb_read_setup(x"40001004", hclk, hsel, haddr, hwrite, htrans);
        wait for 1 ns;
        assert hrdata(7 downto 0) = x"3C"
            report "GPIO TEST FAILED: SWITCH readback mismatch" severity failure;
        report "GPIO: SWITCH read OK" severity note;

        -- Drive a button, wait past debounce, read BUTTON
        btn <= "00010";
        wait for 400 ns;   -- >> debounce window (8 cycles)
        ahb_read_setup(x"40001008", hclk, hsel, haddr, hwrite, htrans);
        wait for 1 ns;
        assert hrdata(4 downto 0) = "00010"
            report "GPIO TEST FAILED: BUTTON debounced readback mismatch" severity failure;
        report "GPIO: BUTTON debounce read OK" severity note;

        report "GPIO TEST PASSED" severity note;
        done <= true;
        wait;
    end process;

end architecture sim;

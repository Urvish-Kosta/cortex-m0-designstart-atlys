# Hardware

## Target board

| Item | Detail |
|---|---|
| Board | Digilent Atlys |
| FPGA | Xilinx Spartan-6 **XC6SLX45-CSG324** (speed grade -2 typical) |
| Logic | 6,822 slices (4× 6-input LUTs + 8 FFs each) |
| Block RAM | 2.1 Mbit — the SoC uses 512 Kbit (64 KB) for boot memory |
| Clock | 100 MHz onboard oscillator (divided to 50 MHz system clock) |
| Serial | On-board USB-UART bridge (shows up as a COM port on the host) |
| Config | Digilent Adept over USB; optional SPI flash for persistence |

## Bill of materials

No external components are required beyond the board itself.

| Qty | Item | Purpose |
|---|---|---|
| 1 | Digilent Atlys board | Everything |
| 1 | USB-A to micro-B cable (PROG port) | FPGA configuration via Adept |
| 1 | USB-A to micro-B cable (UART port) | Serial console |
| (opt) | LED + resistor on PMOD JA1 | External view of the PWM output |

## Board I/O used by the design

| Signal (top level) | Board resource | Direction | Notes |
|---|---|---|---|
| `clk_100m` | 100 MHz oscillator | in | divided to 50 MHz internally |
| `rst_btn`  | BTNU push button | in | active-high reset |
| `uart_tx` / `uart_rx` | USB-UART bridge | out / in | 9600 8N1 default |
| `led[7:0]` | LD0–LD7 | out | animation output |
| `sw[7:0]`  | SW0–SW7 | in | sets PWM duty |
| `btn[3:0]` | BTND / BTNL / BTNR / BTNC | in | task select (BTN0–BTN3) |
| `pwm_led`  | PMOD JA pin 1 | out | PWM brightness output |

Button mapping rationale: BTNU is consumed as reset, so the four task buttons
BTN0–BTN3 in the firmware map to the remaining physical buttons
(BTND, BTNL, BTNR, BTNC respectively).

## Wiring

There is no external wiring for the base demonstrator — every input and output
is on the board. If you want to observe the PWM output, connect an LED (with a
series resistor, e.g. 330 Ω) or an oscilloscope probe between PMOD **JA pin 1**
and **GND** (JA pin 5).

```
 PMOD JA (top row):   [JA1=pwm_led] [JA2] [JA3] [JA4] [GND] [VCC]
                          |                            |
                         LED ---- 330R ----------------+
```

## ⚠ Pin verification required

`constraints/atlys.ucf` contains the pin assignments used by this
reconstruction. **Verify every `LOC` against the Digilent Atlys master UCF for
your board revision** before building a bitstream — pin locations and
IOSTANDARDs (some Atlys banks are 1.8 V) differ between revisions, and a wrong
IOSTANDARD can prevent the FPGA from configuring. The master UCF is on
Digilent's Atlys resource page.

## Configuration and persistence

The bitstream is loaded into the FPGA with **Digilent Adept** (Config tab).
Loaded this way, configuration is **volatile**: power-cycling the board erases
it — a behaviour explicitly noted in the original project. To persist the
design, write the bitstream to the on-board SPI flash from Adept's Flash tab
(the programming file must be generated with the start-up clock set to CCLK;
in ISE: *Generate Programming File → Startup Options → CCLK*).

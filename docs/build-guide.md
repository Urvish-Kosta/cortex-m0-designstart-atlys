# Build guide

Three independent flows. Only the last one needs the Arm core and Xilinx tools.

## 1. Firmware (any Linux/macOS/WSL host)

Requires `gcc-arm-none-eabi` and Python 3.

```bash
make -C firmware
```

Outputs in `firmware/build/`:

| File | Purpose |
|---|---|
| `firmware.elf` | linked image with symbols (debugging) |
| `firmware.bin` | raw binary |
| `firmware.hex` | one 32-bit word per line — loaded by `ahb_mem.vhd` |

The build is warning-clean under `-Wall -Wextra -Werror`. The original project
used **Keil MDK**; the same sources build there too (create a uVision project,
add `src/*.c`, `src/startup.S` won't be needed — use Keil's startup — and set
the scatter file to match `link.ld`'s single 64 KB region at `0x0`).

## 2. Simulation and tests (no Arm core needed)

Requires `ghdl` and `gcc`.

```bash
./sim/scripts/run_tests.sh    # VHDL testbenches: UART, GPIO, PWM
make -C firmware/test         # Unity unit tests for the pattern logic
```

Both are run by CI on every push (`.github/workflows/ci.yml`).

To view waveforms, add `--vcd=wave.vcd` to the `ghdl -r` line in the script
and open the file in GTKWave.

## 3. Bitstream (Xilinx ISE 14.7 + Arm core + Atlys)

Spartan-6 is only supported by **ISE 14.7** (not Vivado). ISE 14.7 is
end-of-life but still downloadable from AMD's website (free WebPACK licence
covers the LX45).

1. **Get the Arm core** — follow
   [`third_party/arm_cortex_m0_designstart/README.md`](../third_party/arm_cortex_m0_designstart/README.md).
2. **Create an ISE project** targeting `xc6slx45-2csg324`.
3. **Add sources**:
   - all files under `rtl/soc/` and `rtl/peripherals/`
   - the Arm deliverables from `third_party/arm_cortex_m0_designstart/`
     (the obfuscated `CORTEXM0DS` module and its includes)
   - `constraints/atlys.ucf`
   - **Do not add** `sim/testbenches/cortexm0ds_stub.vhd` — it would conflict
     with the real core. The stub is for simulation without Arm IP only.
4. **Firmware into BRAM** — two options:
   - *Simple*: copy `firmware/build/firmware.hex` next to the ISE project so
     `ahb_mem.vhd`'s `INIT_FILE` resolves at synthesis (XST supports textio
     init for RAM inference in most cases; check the synthesis report to
     confirm the RAM was inferred as block RAM with init).
   - *Robust*: use `data2mem` with a BMM file to patch the firmware into the
     generated bitstream post-route. This avoids re-synthesising on every
     firmware change and is the recommended production flow.
5. **Set startup clock** to CCLK if you intend to program the SPI flash.
6. **Generate the bitstream** and program with Digilent **Adept**.

### Port-name check

The component declaration for `CORTEXM0DS` in `rtl/soc/cm0ds_top.vhd` follows
the standard DesignStart deliverable. If your package version differs (port
names/widths), adjust the component declaration — it is the single point of
integration.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| ISE: "CORTEXM0DS not found" | Arm deliverables not added to the project |
| Two CORTEXM0DS definitions | The sim stub was added to the ISE project — remove it |
| Garbage on the serial console | Baud mismatch — divisor assumes 50 MHz HCLK |
| LEDs dead but console fine | Pin LOCs wrong for your board rev — check the master UCF |
| Design lost after power cycle | Expected with volatile config — program the SPI flash |

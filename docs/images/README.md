# Images

Screenshots and photographs from the original 2022 project, extracted from the
project report. Each is labelled by what it actually shows.

| File | What it is | Notes |
|---|---|---|
| `atlys-board.png` | The Digilent Atlys (Spartan-6 XC6SLX45) board | Target hardware |
| `atlys-hardware-demo.png` | The board running with the LED row lit, and a PuTTY console showing button presses | Real hardware capture from the project |
| `vivado-block-diagram.png` | Vivado IP Integrator block diagram: the Arm core wired to the peripheral fabric | Design overview |
| `isim-gpio-waveform.png` | ISim simulation waveform of the GPIO demo | Simulation evidence |
| `keil-mdk-simulation.png` | Keil MDK simulation (registers / RTX threads) | Firmware-side simulation |

## Honesty note

The interactive PuTTY task-menu screenshot in the original report displays the
text "Avnet/Digilent **Arty** Evaluation Board", i.e. it was captured from an
Arty-based example rather than the Atlys. It has therefore been **left out** of
this repository to avoid mislabelling hardware. When the demonstrator is next
run on the Atlys, capture a fresh menu screenshot and add it here as
`putty-menu-atlys.png`.

Timing and utilisation figures were not preserved from the original build and
are intentionally not published until re-measured.

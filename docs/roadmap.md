# Roadmap

Ordered roughly by value / effort.

## Near term
- [ ] Replace the behavioural clock divider with a Spartan-6 `DCM_SP`
      primitive (clean clock routing, proper timing constraints).
- [ ] Re-run the full ISE flow on hardware; capture real screenshots for
      `docs/images/` and record utilisation + timing numbers in the README.
- [ ] `data2mem`/BMM flow so firmware updates don't require re-synthesis.

## Medium term
- [ ] SysTick-style hardware timer peripheral; replace busy-wait delays.
- [ ] Interrupt-driven UART RX (wire a UART IRQ into the DesignStart IRQ
      inputs; add NVIC usage to the firmware).
- [ ] AHB-Lite protocol checker assertions in the testbenches.
- [ ] Co-simulation of the real Arm core executing `firmware.hex`
      (personal use of the DesignStart deliverable is licence-compatible;
      only redistribution is not).

## Long term
- [ ] Port to a supported 7-series board (Arty A7 / Nexys A7) under Vivado —
      Spartan-6 and ISE are end-of-life, which limits reproducibility.
- [ ] Optional: swap in an open ARMv6-M-compatible core so the whole repo is
      buildable with zero licence steps, keeping DesignStart as an alternative.

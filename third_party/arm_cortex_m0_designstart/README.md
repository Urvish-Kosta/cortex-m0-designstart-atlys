# Arm Cortex-M0 DesignStart processor (not included)

This project targets the **Arm Cortex-M0 DesignStart** processor as its CPU core.
The core RTL is **licensed intellectual property from Arm** and is **intentionally
not included** in this repository.

Arm distributes the Cortex-M0 DesignStart evaluation package free of charge, but
the licence is granted to the person who downloads it and **does not permit
redistribution**. Committing the core here would violate that licence. This is
standard practice for every DesignStart-based project and is the reason this
directory is otherwise empty.

## How to obtain the core

1. Go to the Arm DesignStart page:
   <https://www.arm.com/resources/designstart>
2. Register / sign in with an Arm account and download the
   **Cortex-M0 DesignStart Eval** package.
3. Accept the Arm end-user licence agreement.
4. Extract the package and copy the processor deliverables into **this**
   directory, preserving the vendor's folder layout. You should end up with
   something like:

   ```
   third_party/arm_cortex_m0_designstart/
   |-- logical/
   |   |-- cortexm0ds/          # obfuscated Cortex-M0 DesignStart core
   |   `-- models/
   |-- CortexM0DesignStart_release_note.txt
   `-- ... (other Arm-provided files)
   ```

   The exact layout depends on the package version you download. What matters is
   that the top-level obfuscated core module (commonly `CORTEXM0DS`) is
   synthesisable from within this directory.

## What this repository provides around the core

Everything that integrates the core into a working system on the Atlys board is
original work and **is** included:

- `rtl/soc/` — top-level SoC wrapper, AHB-Lite address decoder, clock/reset.
- `rtl/peripherals/` — UART, GPIO, PWM peripherals (VHDL, AHB-Lite slaves).
- `firmware/` — bare-metal C application and startup for the demonstrator.
- `constraints/` — Atlys (Spartan-6 XC6SLX45) pin and timing constraints.
- `sim/` — testbenches and simulation scripts for the peripherals.

## Version used in the original project

- Package: **Cortex-M0 DesignStart Eval**
- Core: **Cortex-M0 DesignStart (Arm DDI 0432C, r0p0)** — fixed configuration,
  16 interrupts, slow (32-cycle) multiplier, AHB-Lite **master-only** interface.

> If the module name or port list in the package you download differs from what
> `rtl/soc/cm0ds_top.vhd` expects, adjust the component declaration there. The
> expected interface is documented in `docs/architecture.md`.

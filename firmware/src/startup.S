/*******************************************************************************
 * startup.S
 *
 * Minimal ARMv6-M startup for the Cortex-M0 DesignStart SoC.
 *
 * The Cortex-M0 fetches the initial stack pointer from address 0x0 and the
 * reset vector from 0x4, so the vector table must be the first thing in the
 * image. Code runs directly from the on-chip AHB memory (no copy-to-RAM step
 * is needed because code and data live in the same block RAM), so the reset
 * handler only zeroes .bss and calls main().
 *
 * The DesignStart core has 16 IRQ inputs; they are tied low in this SoC, so
 * all interrupt vectors point at a trap loop.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
    .syntax unified
    .cpu    cortex-m0
    .thumb

/* ------------------------------------------------------------------------- */
/* Vector table                                                              */
/* ------------------------------------------------------------------------- */
    .section .vectors, "a", %progbits
    .align  2
    .globl  __vectors
__vectors:
    .word   __stack_top          /*  0: initial SP                          */
    .word   reset_handler + 1    /*  1: reset (thumb bit set)               */
    .word   trap + 1             /*  2: NMI                                  */
    .word   trap + 1             /*  3: HardFault                            */
    .rept   7
    .word   trap + 1             /*  4-10: reserved                          */
    .endr
    .word   trap + 1             /* 11: SVCall                               */
    .word   trap + 1             /* 12: reserved                             */
    .word   trap + 1             /* 13: reserved                             */
    .word   trap + 1             /* 14: PendSV                               */
    .word   trap + 1             /* 15: SysTick                              */
    .rept   16
    .word   trap + 1             /* 16-31: IRQ0-15 (unused, tied low)        */
    .endr

/* ------------------------------------------------------------------------- */
/* Reset handler                                                             */
/* ------------------------------------------------------------------------- */
    .section .text
    .thumb_func
    .globl  reset_handler
reset_handler:
    /* Zero .bss */
    ldr     r0, =__bss_start
    ldr     r1, =__bss_end
    movs    r2, #0
1:  cmp     r0, r1
    bcs     2f
    str     r2, [r0]
    adds    r0, r0, #4
    b       1b
2:
    bl      main
    /* If main returns, trap. */
    .thumb_func
    .globl  trap
trap:
    b       trap

    .end

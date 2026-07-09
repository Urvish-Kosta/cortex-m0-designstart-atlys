/*******************************************************************************
 * link.ld
 *
 * Linker script for the Cortex-M0 DesignStart SoC. All of code, data and stack
 * live in the single 64 KB on-chip AHB block RAM at 0x0000_0000 (see
 * docs/memory-map.md). The vector table is forced to the very start.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
MEMORY
{
    MEM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

ENTRY(reset_handler)

SECTIONS
{
    .text :
    {
        KEEP(*(.vectors))
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > MEM

    .data :
    {
        . = ALIGN(4);
        *(.data*)
        . = ALIGN(4);
    } > MEM

    .bss :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > MEM

    /* 4 KB stack at the top of memory. */
    __stack_top = ORIGIN(MEM) + LENGTH(MEM);

    /DISCARD/ : { *(.ARM.exidx*) *(.ARM.attributes) }
}

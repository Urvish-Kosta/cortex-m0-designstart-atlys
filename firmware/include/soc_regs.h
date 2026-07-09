/*******************************************************************************
 * soc_regs.h
 *
 * Register definitions for the Cortex-M0 DesignStart SoC on the Atlys board.
 * This header is the C-side mirror of docs/memory-map.md and the VHDL
 * peripherals in rtl/peripherals/. If you change an address or bit here,
 * change it there too.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

#define __IO volatile

/* ---------------------------------------------------------------- UART --- */
typedef struct {
    __IO uint32_t DATA;   /* 0x00: W = TX byte, R = last RX byte             */
    __IO uint32_t STATE;  /* 0x04: bit0 = TX busy, bit1 = RX ready           */
    __IO uint32_t BAUD;   /* 0x08: divisor = f_clk / baud                    */
} uart_regs_t;

#define UART_BASE       0x40000000u
#define UART            ((uart_regs_t *) UART_BASE)
#define UART_STATE_TXBUSY   (1u << 0)
#define UART_STATE_RXREADY  (1u << 1)

/* ---------------------------------------------------------------- GPIO --- */
typedef struct {
    __IO uint32_t LED;    /* 0x00: [7:0] LED outputs                          */
    __IO uint32_t SWITCH; /* 0x04: [7:0] slide switches (read-only)           */
    __IO uint32_t BUTTON; /* 0x08: [4:0] debounced push buttons (read-only)   */
} gpio_regs_t;

#define GPIO_BASE       0x40001000u
#define GPIO            ((gpio_regs_t *) GPIO_BASE)

/* Button bit positions (Atlys BTNU/BTNL/BTND/BTNR/BTNC mapping is defined
 * in constraints/atlys.ucf; firmware only cares about the logical index). */
#define BTN0            (1u << 0)
#define BTN1            (1u << 1)
#define BTN2            (1u << 2)
#define BTN3            (1u << 3)
#define BTN4            (1u << 4)

/* ----------------------------------------------------------------- PWM --- */
typedef struct {
    __IO uint32_t DUTY;   /* 0x00: [7:0] duty cycle                           */
    __IO uint32_t EN;     /* 0x04: [0] enable                                 */
} pwm_regs_t;

#define PWM_BASE        0x40002000u
#define PWM             ((pwm_regs_t *) PWM_BASE)

/* --------------------------------------------------------------- Clock --- */
#define SYSTEM_CLK_HZ   50000000u
#define DEFAULT_BAUD    9600u

#endif /* SOC_REGS_H */

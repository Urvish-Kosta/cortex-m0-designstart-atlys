/*******************************************************************************
 * main.c -- GPIO/UART demonstrator for the Cortex-M0 DesignStart SoC.
 *
 * Reproduces the interactive serial demonstrator from the original project: a
 * menu on a 9600 8N1 serial console (PuTTY on the host), with tasks selected
 * by the Atlys push buttons:
 *
 *   BTN0 : print the current PWM duty value over UART
 *   BTN1 : "Cylon" LED display (single lit LED bounces end to end)
 *   BTN2 : scrolling LED display (lit LED walks across and wraps)
 *   BTN3 : stop the current task and return to this menu
 *
 * The slide switches set the PWM duty cycle; the PWM output drives an LED so
 * the brightness is visible. Bare-metal, polled I/O, no interrupts, no RTOS.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#include <stdint.h>
#include "soc_regs.h"
#include "uart.h"
#include "demo_tasks.h"

/* Approximate busy-wait delay. Timing precision is unimportant here: this only
 * paces LED animations for human eyes. ~8 cycles per loop iteration. */
static void delay_ms(uint32_t ms)
{
    volatile uint32_t n = ms * (SYSTEM_CLK_HZ / 8000u);
    while (n--) {
        /* spin */
    }
}

static void print_menu(void)
{
    uart_puts("\n");
    uart_puts("****************************************************\n");
    uart_puts("**  Cortex-M0 DesignStart on Digilent Atlys       **\n");
    uart_puts("**  LEDs and switches GPIO demonstration          **\n");
    uart_puts("****************************************************\n");
    uart_puts("Choose Task:\n");
    uart_puts("BTN0: Print PWM value.\n");
    uart_puts("BTN1: 'Cylon' LED display.\n");
    uart_puts("BTN2: Scrolling LED display.\n");
    uart_puts("BTN3: Return to this menu.\n");
    uart_puts("\n");
}

/* Wait until all buttons are released, so one press = one action. */
static void wait_buttons_released(void)
{
    while (GPIO->BUTTON != 0u) {
        /* wait */
    }
}

int main(void)
{
    cylon_state_t  cylon;
    scroll_state_t scroll;
    uint32_t       buttons;

    uart_init(DEFAULT_BAUD);

    /* PWM duty tracks the slide switches; output enabled. */
    PWM->DUTY = GPIO->SWITCH;
    PWM->EN   = 1u;

    print_menu();

    for (;;) {
        buttons = GPIO->BUTTON;

        if (buttons & BTN0) {
            wait_buttons_released();
            PWM->DUTY = GPIO->SWITCH;            /* refresh from switches */
            uart_puts("PWM value: ");
            uart_put_u8_dec((uint8_t)PWM->DUTY);
            uart_puts("\n");

        } else if (buttons & BTN1) {
            wait_buttons_released();
            uart_puts("'Cylon' LED display. Press BTN3 to stop.\n");
            cylon_init(&cylon);
            while ((GPIO->BUTTON & BTN3) == 0u) {
                GPIO->LED = cylon_step(&cylon);
                delay_ms(100u);
            }
            wait_buttons_released();
            GPIO->LED = 0u;
            print_menu();

        } else if (buttons & BTN2) {
            wait_buttons_released();
            uart_puts("Scrolling LED display. Press BTN3 to stop.\n");
            scroll_init(&scroll);
            while ((GPIO->BUTTON & BTN3) == 0u) {
                GPIO->LED = scroll_step(&scroll);
                delay_ms(100u);
            }
            wait_buttons_released();
            GPIO->LED = 0u;
            print_menu();

        } else if (buttons & BTN3) {
            wait_buttons_released();
            print_menu();
        }
    }

    return 0;   /* unreachable */
}

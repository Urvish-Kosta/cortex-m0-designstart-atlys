/*******************************************************************************
 * uart.c -- polled UART driver for the AHB UART peripheral.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#include "soc_regs.h"
#include "uart.h"

void uart_init(uint32_t baud)
{
    UART->BAUD = SYSTEM_CLK_HZ / baud;
}

void uart_putc(char c)
{
    while (UART->STATE & UART_STATE_TXBUSY) {
        /* wait for transmitter */
    }
    UART->DATA = (uint32_t)(uint8_t)c;
}

void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n') {
            uart_putc('\r');
        }
        uart_putc(*s++);
    }
}

int uart_rx_ready(void)
{
    return (UART->STATE & UART_STATE_RXREADY) != 0;
}

char uart_getc(void)
{
    while (!uart_rx_ready()) {
        /* wait for a byte */
    }
    return (char)(UART->DATA & 0xFFu);
}

void uart_put_u8_dec(uint8_t v)
{
    char buf[3];
    int  i = 0;

    if (v == 0) {
        uart_putc('0');
        return;
    }
    while (v > 0) {
        buf[i++] = (char)('0' + (v % 10));
        v /= 10;
    }
    while (i > 0) {
        uart_putc(buf[--i]);
    }
}

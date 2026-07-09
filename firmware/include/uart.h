/*******************************************************************************
 * uart.h -- polled UART driver interface.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#ifndef UART_H
#define UART_H

#include <stdint.h>

void uart_init(uint32_t baud);
void uart_putc(char c);
void uart_puts(const char *s);      /* expands '\n' to "\r\n" */
int  uart_rx_ready(void);
char uart_getc(void);               /* blocking */
void uart_put_u8_dec(uint8_t v);    /* print 0..255 in decimal */

#endif /* UART_H */

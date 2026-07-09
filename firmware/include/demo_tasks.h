/*******************************************************************************
 * demo_tasks.h -- LED pattern generators for the demonstrator.
 *
 * These functions are pure (no hardware access): given the current animation
 * state they return the next 8-bit LED pattern. main.c owns the timing and
 * writes the result to the GPIO LED register. Keeping them pure means they can
 * be unit-tested on the host with Unity (see firmware/test/).
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#ifndef DEMO_TASKS_H
#define DEMO_TASKS_H

#include <stdint.h>

/* State for the "Cylon" bouncing-LED animation. */
typedef struct {
    uint8_t pos;        /* 0..7, index of the lit LED       */
    int8_t  dir;        /* +1 moving left, -1 moving right  */
} cylon_state_t;

void    cylon_init(cylon_state_t *s);
uint8_t cylon_step(cylon_state_t *s);   /* returns next LED pattern */

/* State for the scrolling (rotating) LED animation. */
typedef struct {
    uint8_t pos;        /* 0..7 */
} scroll_state_t;

void    scroll_init(scroll_state_t *s);
uint8_t scroll_step(scroll_state_t *s); /* returns next LED pattern */

#endif /* DEMO_TASKS_H */
